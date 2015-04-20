//
//  DUIManager.m
//  DistributedUI
//
//  Created by Caleb Cannon on 4/8/15.
//  Copyright (c) 2015 Caleb Cannon. All rights reserved.
//



#import "DUIManager.h"



NSString * const DUIManagerSessionStartedNotification = @"DUIManagerDidStartNotification";
NSString * const DUIManagerSessionEndedNotification = @"DUIManagerDidStopNotification";
NSString * const DUIManagerDidRegisterObjectNotification = @"DUIManagerDidRegisterObjectNotification";
NSString * const DUIManagerDidUnregisterObjectNotification = @"DUIManagerDidUnregisterObjectNotification";
NSString * const DUIManagerFoundPeerNotification = @"DUIManagerDidDiscoverServiceNotification";
NSString * const DUIManagerDidRemoveServiceNotification = @"DUIManagerDidRemoveServiceNotification";

NSString * const kDUIManagerPeer = @"DUIManagerPeer";




// Private interface for the DUI mananger.
@interface DUIManager () <MCNearbyServiceAdvertiserDelegate, MCAdvertiserAssistantDelegate, MCNearbyServiceBrowserDelegate, MCSessionDelegate>

// Multi-Peer connectivity objects
@property (strong) MCSession *session;
@property (readonly) MCPeerID *localPeerID;
@property (readonly) MCNearbyServiceAdvertiser *nearbyServiceAdvertiser;
@property (readonly) MCNearbyServiceBrowser *nearbyServiceBrowser;
@property (readonly) NSDictionary *discoveryInfo;

// Discovered and connected service lists
@property (readonly) NSMutableSet *mutableDiscoveredPeers;
@property (readonly) NSMutableSet *mutableConnectedPeers;

// Local objects registrations are added to this hash table. The hash table is weakly
// referenced and the DUIDistributedObjectData instances are associated weakly or strongly
// with their objects, thus defining the lifetime of the object data
@property (retain) NSHashTable *distributedObjectsTable;

// When registering observation info for a remote peer this hash table associated the
// NSNotificationObserver with the DUIPeer.  When the peer disconnects we remove
// the observation info for the peer.
@property (retain) NSMapTable *distributedNotificationObservers;

// Mutable array used to store remote object proxies.
@property (retain) NSMutableArray *mutableRemoteObjectProxies;

// Mutable array used to store distributed notifiation data
@property (readonly) NSMutableArray *distributedNotificationData;

// Accessor for the host peer.  Returns nil if the reciever is host.
@property (readonly) DUIPeer *hostPeer;

@end




/**
 These classes box the distributed objects added using the [DUIManager addDistributedObject:retain:] method. The
 DUI manager uses a weakly referencing NSHashTable for storage. This means the object data is removed unless it
 is retained somewhere else. We associate the distributed object data with the object strongly so that when the
 object is released the object data is released as well.
*/
@interface DUIDistributedObjectData : NSObject <NSCopying>

- (instancetype) initWithObject:(id)object identifier:(DUIObjectIdentifier *)identifier;

@property (readonly, copy) DUIObjectIdentifier *identifier;
@property (readonly, weak) id object;

// Retain/release the referenced object.  This can be used, e.g., for distributed singletons that are stored
// weakly by the application.  When the DUI session is ended those objects will be released automatically.
- (void) retainObject;
- (void) releaseObject;
@property (readonly, getter=objectIsRetained) BOOL objectRetained;

@end



/**
 Boxing class for singleton object data
*/
@interface DUISharedSingletonObjectData : NSObject

@property (readonly, copy) DUISingletonIdentifier *identifier;
@property (readonly) SEL selector;

- (instancetype) initWithSelector:(SEL)selector identifier:(DUISingletonIdentifier *)identifier;

@end




@implementation DUIManager

// Global pointer to theshared maanager
static DUIManager *__sharedDUIManager = nil;

+ (instancetype) sharedDUIManager
{
	static dispatch_once_t predicate;
	dispatch_once(&predicate, ^{
		if (__sharedDUIManager == nil)
			__sharedDUIManager = [[self alloc] init];
	});
	
	return __sharedDUIManager;
}

// Set the shared mananger - Used internally for testing
+ (void) setSharedDUIManager:(DUIManager *)manager
{
	__sharedDUIManager = manager;
}

// Initializes with the app display name as the service type and no advertisement info
- (instancetype)init
{
	NSString *displayName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
	if (!displayName)
		displayName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];

	self = [self initWithServiceType:displayName info:nil];
	
	return self;
}

- (instancetype) initWithServiceType:(NSString *)type info:(NSDictionary *)info
{
	self = [super init];
	if (self)
	{
		// Get the device name depending on the platform
#if TARGET_OS_IPHONE
		NSString *deviceName = [[UIDevice currentDevice] name];
#else
		NSString *deviceName = [[NSHost currentHost] localizedName];
#endif

		// Set up the MultiPeer Connectivity objects
		_localPeerID = [[MCPeerID alloc] initWithDisplayName:deviceName];

		// TODO: Enable security
		_discoveryInfo = [info copy];
		_serviceType = [type copy];
		
		// Setup local notifications
		[self registerForLocalNotifications];
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Session Management

@synthesize sessionActive = _sessionActive;
@synthesize nearbyServiceAdvertiser = _nearbyServiceAdvertiser;
@synthesize nearbyServiceBrowser = _nearbyServiceBrowser;

- (void) startDistributedInterfaceSession
{
	@synchronized(self)
	{
		// Create our storage objects
		_distributedObjectsTable = [NSHashTable weakObjectsHashTable];
		_distributedNotificationObservers = [NSMapTable strongToStrongObjectsMapTable];
		_distributedNotificationData = [NSMutableArray array];
		_mutableRemoteObjectProxies = [NSMutableArray array];
		_mutableDiscoveredPeers = [NSMutableSet set];
		_mutableConnectedPeers = [NSMutableSet set];
	}
}

- (void)startDistributedInterfaceHostSession
{
	// Skip if host session already active
	if (self.isSessionActive && self.host)
		return;
	
	@synchronized(self)
	{
		[self stopDistributedInterfaceSession];
		DUILog(DUILogInfo, @"Starting DUI host session... %@", self.serviceType);
		[self startDistributedInterfaceSession];
		
		_session = [[MCSession alloc] initWithPeer:_localPeerID securityIdentity:nil encryptionPreference:MCEncryptionOptional];
		_session.delegate = self;

		_nearbyServiceAdvertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.localPeerID discoveryInfo:self.discoveryInfo serviceType:self.serviceType];
		_nearbyServiceAdvertiser.delegate = self;
		[_nearbyServiceAdvertiser startAdvertisingPeer];

		for (id<NSObject> observer in self.distributedNotificationObservers)
			[[NSNotificationCenter defaultCenter] removeObserver:observer];
		
		_host = YES;
		_sessionActive = YES;
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:DUIManagerSessionStartedNotification object:self];
}

- (void)startDistributedInterfaceClientSession
{
	// Skip if client session already active
	if (self.isSessionActive && !self.host)
		return;

	@synchronized(self)
	{
		[self stopDistributedInterfaceSession];
		DUILog(DUILogInfo, @"Starting DUI client session... %@", self.serviceType);
		[self startDistributedInterfaceSession];

		_session = [[MCSession alloc] initWithPeer:_localPeerID securityIdentity:nil encryptionPreference:MCEncryptionOptional];
		_session.delegate = self;

		_nearbyServiceBrowser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.localPeerID serviceType:self.serviceType];
		_nearbyServiceBrowser.delegate = self;
		[_nearbyServiceBrowser startBrowsingForPeers];

		_host = NO;
		_sessionActive = YES;
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:DUIManagerSessionStartedNotification object:self];
}

- (void) stopDistributedInterfaceSession
{
	if (!_sessionActive)
		return;
	
	@synchronized(self)
	{
		DUILog(DUILogInfo, @"Stopping DUI session...");
		
		[[NSNotificationCenter defaultCenter] removeObserver:self];
		
		[_nearbyServiceAdvertiser stopAdvertisingPeer], _nearbyServiceAdvertiser = nil;;
		[_nearbyServiceBrowser stopBrowsingForPeers], _nearbyServiceBrowser = nil;
		
		[self.session disconnect];
		self.session = nil;
		
		// Free our storage objects
		@synchronized(self.distributedObjectsTable)
		{
			for (DUIDistributedObjectData *objectData in self.distributedObjectsTable)
				[objectData releaseObject];
		}
		_distributedObjectsTable = nil;
		_mutableRemoteObjectProxies = nil;
		_mutableDiscoveredPeers = nil;
		_mutableConnectedPeers = nil;
		
		_host = NO;
		_sessionActive = NO;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DUIManagerSessionEndedNotification object:self];
}

- (DUIPeer *) hostPeer
{
	// If we are hosting return nil, otherwise return the first object in the connected
	// netservices list
	
	if (self.isHost)
		return nil;
	
	DUIPeer *hostPeer = [self.mutableConnectedPeers anyObject];
	return hostPeer;
}

@synthesize serviceType = _serviceType;

- (NSString *)serviceType
{
	return _serviceType;
}

- (void)setServiceType:(NSString *)serviceType
{
	if (self.isSessionActive)
		[NSException raise:DUIException format:@"Can not change service type while session is active"];
	_serviceType = serviceType;
}

#pragma mark - Notification Handling

- (void) postLocalNotification:(NSNotification *)notification
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotification:notification];
	});
}


#pragma mark - Notification Handling

- (void) addDistributedNotificationObserver:(id)observer selector:(SEL)selector name:(NSString *)name object:(id)object
{
	if (!self.sessionActive)
	{
		[NSException raise:DUIException format:@"Can not add observers while session is inactive"];
	}
	
	if (object != nil && ![object isKindOfClass:[DUIRemoteObjectProxy class]])
	{
		[[NSNotificationCenter defaultCenter] addObserver:observer selector:selector name:name object:object];
		return;
	}
	
	if (object == nil)
	{
		[[NSNotificationCenter defaultCenter] addObserver:observer selector:selector name:name object:object];
	}
	
	DUIObjectIdentifier *observerIdentifier = [DUIObjectIdentifier identifierForObject:observer representedClass:[observer class]];
	DUIObjectIdentifier *objectIdentifier = [DUIObjectIdentifier identifierForObject:object representedClass:[object class]];
	
	DUINotificationObservationInfo *notificationObservationInfo = [[DUINotificationObservationInfo alloc] initWithName:name objectIdentifier:objectIdentifier observerIdentifier:observerIdentifier selector:selector];
	
	// Associate the object data with the object so that is it dealloced in sequence with the object
	const char *associationKey = [observerIdentifier.description UTF8String];
	objc_setAssociatedObject(observer, associationKey, notificationObservationInfo, OBJC_ASSOCIATION_ASSIGN);
	
	[self.distributedNotificationData addObject:notificationObservationInfo];
	
	// Register the object with remote services
	@synchronized(self.mutableConnectedPeers)
	{
		for (DUIPeer *peer in self.mutableConnectedPeers)
			[peer sendObject:notificationObservationInfo];
	}
	
	DUILog(DUILogDebug, @"Added distributed notification: %@", notificationObservationInfo);
}

#pragma mark - Distributed Object Handling

- (DUIObjectIdentifier *) addDistributedObject:(id)object retain:(BOOL)shouldRetain
{
	DUIObjectIdentifier *identifier = [DUIObjectIdentifier identifierForObject:object representedClass:nil];
	return [self addDistributedObject:object withIdentifier:identifier retain:shouldRetain];
}

- (DUIObjectIdentifier *) addDistributedObject:(id)object withIdentifier:(DUIObjectIdentifier *)identifier retain:(BOOL)shouldRetain
{
	DUIDistributedObjectData *distributedObjectData = [[DUIDistributedObjectData alloc] initWithObject:object identifier:identifier];
	
	// Associate the object data with the object so that is it automagically dealloced in sequence with the object
	const char *associationKey = [identifier.description UTF8String];
	objc_setAssociatedObject(object, associationKey, distributedObjectData, OBJC_ASSOCIATION_RETAIN);
	
	// Create a circular reference so the object and data remain valid
	if (shouldRetain)
		[distributedObjectData retainObject];
	
	@synchronized(self.distributedObjectsTable)
	{
		[self.distributedObjectsTable addObject:distributedObjectData];
	}
	
	// Register the object with remote services
	@synchronized(self.mutableConnectedPeers)
	{
		for (DUIPeer *duiPeer in self.mutableConnectedPeers)
			[duiPeer sendObject:identifier];
	}
	
	DUILog(DUILogDebug, @"added distributed object: %@", distributedObjectData);
	
	return identifier;
}

- (void) removeDistributedObject:(id<DUIDistrubtedObject>)object
{
	DUIDistributedObjectData *objectData = [self distributedObjectDataForObject:object];

	DUILog(DUILogDebug, @"Removing distributed object: %@", objectData);
	@synchronized(self.distributedObjectsTable)
	{
		[self.distributedObjectsTable removeObject:objectData];
	}
}

- (void) removeAllDistributedObjects
{
	@synchronized(self.distributedObjectsTable)
	{
		[self.distributedObjectsTable removeAllObjects];
	}
}

- (id) distributedObjectDataForObject:(id)object
{
	@synchronized(self.distributedObjectsTable)
	{
		for (DUIDistributedObjectData *objectData in self.distributedObjectsTable)
			if (objectData.object == object)
				return objectData;
	}
	
	return nil;
}

- (id) objectWithIdentifier:(DUIIdentifier *)identifier;
{
	@synchronized(self.distributedObjectsTable)
	{
		for (DUIDistributedObjectData *objectData in self.distributedObjectsTable)
			if ([objectData.identifier isEqualToIdentifier:identifier])
				return objectData.object;
	}
	
	return nil;
}

// Returns the network identifier for the given object. Returns nil if the object is not registered as a distributed object.
- (DUIObjectIdentifier *) identifierForObject:(id)object;
{
	for (DUIDistributedObjectData *objectData in self.distributedObjectsTable)
		if (objectData.object == object)
			return objectData.identifier;
	
	return nil;
}

#pragma mark - Accessors

- (NSArray *) discoveredPeers
{
	if (self.isHost)
		return nil;
	
	return [self.mutableDiscoveredPeers allObjects];
}

- (NSArray *) connectedPeers
{
	return [self.mutableConnectedPeers allObjects];
}

- (NSArray *) remoteObjectProxies
{
	NSArray *proxies = [NSArray arrayWithArray:self.mutableRemoteObjectProxies];
	return proxies;
}

- (NSArray *) distributedObjects
{
	NSArray *objects = [[self.distributedObjectsTable allObjects] valueForKey:@"object"];
	return objects;
}

- (NSUInteger) distributedObjectsCount
{
	NSUInteger count = self.distributedObjectsTable.allObjects.count;
	return count;
}

#pragma mark - Methods

- (void) connectPeer:(DUIPeer *)peer
{
	[self.session connectPeer:peer.peerID withNearbyConnectionData:nil];
}

- (void) disconnectPeer:(DUIPeer *)peer;
{
	
}

- (DUIPeer *) peerWithPeerID:(MCPeerID *)peerID
{
	@synchronized(self.mutableDiscoveredPeers)
	{
		for (DUIPeer *peer in self.mutableDiscoveredPeers)
			if ([peer.peerID isEqual:peerID])
				return peer;
	}
	
	return nil;
}

- (void) notifyLocalConnectionForPeer:(DUIPeer *)peer
{
#if TARGET_OS_IPHONE
#else
#endif
}

- (void) registerForLocalNotifications
{

#if TARGET_OS_IPHONE
#else
#endif
}

#pragma mark - Convenience functions

/// Returns the remote object proxy for the given idenifier
- (DUIRemoteObjectProxy *) remoteObjectProxyForIdentifier:(DUIIdentifier *)identifier
{
	DUIRemoteObjectProxy *result = nil;
	@synchronized(_mutableRemoteObjectProxies)
	{
		for (DUIRemoteObjectProxy *proxy in self.mutableRemoteObjectProxies)
		{
			if ([proxy.identifier isEqualToIdentifier:identifier])
			{
				result = proxy;
				break;
			}
		}
	}
	
	// For singletons, create the proxy if not present
	if (result == nil && [identifier isKindOfClass:[DUISingletonIdentifier class]])
	{
		DUIRemoteObjectProxy *proxy = [[DUIRemoteObjectProxy alloc] initWithIdentifier:(DUISingletonIdentifier *)identifier
																			   peer:self.hostPeer];
		[self addRemoteObjectProxy:proxy];
		result = proxy;
	}
	
	return result;
}

- (void) addRemoteObjectProxy:(DUIRemoteObjectProxy *)proxy
{
	[self.mutableRemoteObjectProxies addObject:proxy];
}

- (void) removeRemoteObjectProxy:(DUIRemoteObjectProxy *)proxy
{
	[self.mutableRemoteObjectProxies removeObject:proxy];
}

#pragma mark - DUIPeer Methods


#pragma mark - DUINetServiceDelegate methods

- (void) duiPeer:(DUIPeer *)peer didReceiveRemoteObjectRegistration:(DUIObjectIdentifier *)objectIdentifier
{
	DUILog(DUILogDebug, @"registered object: %@", objectIdentifier);
	[self addRemoteObjectProxy:[[DUIRemoteObjectProxy alloc] initWithIdentifier:objectIdentifier peer:peer]];
}

- (void) duiPeer:(DUIPeer *)peer didReceiveRemoteInvocation:(DUIInvocation *)duiInvocation
{
	DUILog(DUILogDebug, @"received invocation: %@", duiInvocation);
	
	void(^performInvocation)() = ^() {
		id object = [self objectWithIdentifier:duiInvocation.objectIdentifier];
		
		assert(object != nil);
		
		if (object)
		{
			[duiInvocation.invocation invokeWithTarget:object];
			[peer forwardResultForInvocation:duiInvocation];
		}
	};
	
	if (![[NSThread currentThread] isMainThread])
		dispatch_sync(dispatch_get_main_queue(), performInvocation);
	else
		performInvocation();
}

// TODO: Move this method into peer class
- (void) duiPeer:(DUIPeer *)peer didReceiveRemoteInvocationResponse:(DUIInvocationResponse *)response forInvocation:(DUIInvocation *)invocation
{
	DUILog(DUILogDebug, @"received invocation response %@ for invocation %@", response.invocationIdentifier, invocation.identifier);
	DUIIdentifier *invocationIdentifier = response.invocationIdentifier;
	
	if (!invocation)
	{
		DUILog(DUILogDebug, @"Could not find invocation with identifier: %@", invocationIdentifier);
		[NSException raise:@"Invocation not found" format:@"Could not find the invocation with identifier %@.", invocationIdentifier];
	}
	
	[response setForInvocation:invocation];
}

- (void) duiPeer:(DUIPeer *)peer willForwardDistributedInvocation:(DUIInvocation *)invocation
{
	DUILog(DUILogDebug, @"%@ will forward invocation: %@", peer, invocation);
}

- (void) duiPeer:(DUIPeer *)peer didForwardDistributedInvocation:(DUIInvocation *)invocation
{
	DUILog(DUILogDebug, @"%@ did forward invocation: %@", peer, invocation);
}

- (void)duiPeer:(DUIPeer *)peer didReceiveRemoteNotificationObservationInfo:(DUINotificationObservationInfo *)observationInfo
{
	DUILog(DUILogDebug, @"%@ received remote notification observer: %@", peer, observationInfo);

	if ([self.distributedNotificationData containsObject:observationInfo])
		return;
	
	id object = [self objectWithIdentifier:observationInfo.objectIdentifier];
	[self.distributedNotificationData addObject:observationInfo];
	
	__weak DUIManager *weakSelf = self;
	id <NSObject> observer = [[NSNotificationCenter defaultCenter] addObserverForName:observationInfo.name
																			   object:object
																				queue:nil
																		   usingBlock:^(NSNotification *notification) {
																			   
																			   // Skip remote notifications - this block only forwards local notifications
																			   if ([notification isKindOfClass:[DUINotification class]])
																				   return;
																			   
																			   DUILog(DUILogDebug, @"Received local notification: %@", notification);
																			   
																			   // TODO: The current implementation forwards the notification to the host which then forwards
																			   // the notification to the remaining connected clients.  Using MPC all clients are connected
																			   // to each other and it is possible to forward the notification directly to each client
																			   
																			   DUINotification *duiNotification = [DUINotification notificationWithNotification:notification];
																			   NSArray *peers = weakSelf.connectedPeers;
																			   for (DUIPeer *peer in peers)
																				   [peer sendObject:duiNotification];
																		   }];

	[self.distributedNotificationObservers setObject:peer forKey:observer];
	
	DUILog(DUILogDebug, @"registered remote notification observer: %@", observationInfo);
}

- (void)duiPeer:(DUIPeer *)duiPeer didReceiveRemoteNotification:(DUINotification *)notification
{
	DUILog(DUILogDebug, @"received remote notification: %@", notification);
	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotification:(NSNotification *)notification];
	});
}

#pragma mark - MultiPeer session methods

// Remote peer changed state
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
	DUILog(DUILogMultipeerSession, @"session: peer:%@ didChangeState:%li", peerID, (long)state);
	
	DUIPeer *peer = [self peerWithPeerID:peerID];

	if (state == MCSessionStateConnected)
	{
		if (peer == nil)
			return;

		@synchronized(self.mutableConnectedPeers)
		{
			[self.mutableConnectedPeers addObject:peer];
		}
		
		// Forward distributed objects to the service
		@synchronized(self.distributedObjectsTable)
		{
			for (DUIDistributedObjectData *objectData in self.distributedObjectsTable)
				[peer sendObject:objectData.identifier];
		}
		
		// Forward distributed notification listeners
		@synchronized(self.distributedNotificationData)
		{
			for (DUINotificationObservationInfo *observationInfo in self.distributedNotificationData)
				[peer sendObject:observationInfo];
		}

		NSDictionary *userInfo = @{ kDUIManagerPeer : peer };
		[[NSNotificationCenter defaultCenter] postNotificationName:DUIPeerDidConnect object:self userInfo:userInfo];
		DUILog(DUILogMultipeerSession, @"connected peer: %@", peer);

		// Notify the user that a new peer connected
		[self notifyLocalConnectionForPeer:peer];
	}
	
	else if (state == MCSessionStateNotConnected && [self.connectedPeers containsObject:peer])
	{
		@synchronized(self.mutableConnectedPeers)
		{
			[self.mutableConnectedPeers removeObject:peer];
		}
		
		NSArray *observers = self.distributedNotificationObservers.keyEnumerator.allObjects;
		dispatch_apply(observers.count, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^(size_t index) {
			id<NSObject>observer = observers[index];
			DUIPeer *observingPeer = [self.distributedNotificationObservers objectForKey:observer];
			if (observingPeer == peer)
			{
				@synchronized(self.distributedNotificationObservers)
				{
					[[NSNotificationCenter defaultCenter] removeObserver:observer];
					[self.distributedNotificationObservers removeObjectForKey:observer];
				}
			}
		});
		
		NSDictionary *userInfo = @{ kDUIManagerPeer : peer };
		[[NSNotificationCenter defaultCenter] postNotificationName:DUIPeerDidDisconnect object:self userInfo:userInfo];
		DUILog(DUILogMultipeerSession, @"disconnected peer: %@", peer);
	}
}

// Received data from remote peer
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
	DUILog(DUILogMultipeerSession, @"session: didReceiveData:%@ fromPeer:%@", data, peerID);

	DUIPeer *peer = [self peerWithPeerID:peerID];
	[peer reconstructData:data];
}

// Received a byte stream from remote peer
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
	DUILog(DUILogMultipeerSession, @"session: didReceiveStream: withName:%@ fromPeer:%@", streamName, peerID);
}

// Start receiving a resource from remote peer
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
	DUILog(DUILogMultipeerSession, @"session: didStartReceivingResourceWithName:%@ fromPeer:%@ withProgress:%@", resourceName, peerID, progress);
}

// Finished receiving a resource from remote peer and saved the content in a temporary location - the app is responsible for moving the file to a permanent location within its sandbox
- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
	DUILog(DUILogMultipeerSession, @"session: didFinishReceivingResourceWithName:%@ fromPeer:%@ atURL:%@ withError:%@", resourceName, peerID, localURL, error);
}

// Made first contact with peer and have identity information about the remote peer (certificate may be nil)
- (void)session:(MCSession *)session didReceiveCertificate:(NSArray *)certificate fromPeer:(MCPeerID *)peerID certificateHandler:(void(^)(BOOL accept))certificateHandler
{
	DUILog(DUILogMultipeerSession, @"session: didReceiveCertificate:%@ fromPeer:%@ certificateHandler", certificate, peerID);

	// TODO: Validate certificates
	certificateHandler(YES);
}


#pragma mark - Advertiser assistant methods

// An invitation will be presented to the user
- (void)advertiserAssistantWillPresentInvitation:(MCAdvertiserAssistant *)advertiserAssistant
{
	DUILog(DUILogMultipeerSession, @"advertiserAssistantWillPresentInvitation:");
}

// An invitation was dismissed from screen
- (void)advertiserAssistantDidDismissInvitation:(MCAdvertiserAssistant *)advertiserAssistant
{
	DUILog(DUILogMultipeerSession, @"advertiserAssistantDidDismissInvitation:");
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error
{
	DUILog(DUILogMultipeerSession, @"advertiser: didNotStartAdvertisingPeer:%@", error);
}

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession *))invitationHandler
{
	DUILog(DUILogMultipeerSession, @"advertiser: didReceiveInvitationFromPeer:%@ withContext:%@ invitationHandler:", peerID, context);
	
	DUIPeer *peer = [self peerWithPeerID:peerID];
	if (!peer)
	{
		peer = [[DUIPeer alloc] initWithPeerID:peerID info:nil manager:self];
		@synchronized(self.mutableDiscoveredPeers)
		{
			[self.mutableDiscoveredPeers addObject:peer];
		}
	}

	// TODO: Prompt for connect / use security settings
	invitationHandler(YES, self.session);
}

#pragma mark - Browser assistant methods

- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
	DUILog(DUILogMultipeerSession, @"browser: didNotStartBrowsingForPeers:%@", error);
}

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
	DUILog(DUILogMultipeerSession, @"browser: foundPeer:%@ withDiscoveryInfo:%@", peerID, info);

	DUIPeer *peer = [self peerWithPeerID:peerID];
	if (!peer)
	{
		peer = [[DUIPeer alloc] initWithPeerID:peerID info:nil manager:self];
		@synchronized(self.mutableDiscoveredPeers)
		{
			[self.mutableDiscoveredPeers addObject:peer];
		}
	}
	
	NSDictionary *userInfo = @{ kDUIManagerPeer : peerID, };
	[[NSNotificationCenter defaultCenter] postNotificationName:DUIManagerFoundPeerNotification object:self userInfo:userInfo];
}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
	DUILog(DUILogMultipeerSession, @"browser: lostPeer:%@", peerID);
}



#pragma mark -

- (NSString *)description
{
	//	NSString *description = [[super description] stringByAppendingFormat:@", {\n\tDomain: %@\n\tType: %@\n\tName: %@\n\tHost: %i\n}", self.serviceDomain, self.serviceType, self.serviceName, self.isHost];
	//	return description;
	return [super description];
}


@end




#pragma mark -
@implementation DUIDistributedObjectData

- (instancetype) initWithObject:(id)object identifier:(DUIObjectIdentifier *)identifier
{
	self = [super init];
	if (self)
	{
		_identifier = [identifier copy];
		_object = object;
	}
	return self;
}

- (instancetype) copyWithZone:(NSZone *)zone
{
	id newData = [[[self class] allocWithZone:zone] initWithObject:self.object identifier:self.identifier];
	
	if (_objectRetained)
		[newData retainObject];
	
	return newData;
}

// Retains the object and set the retained flag
- (void) retainObject
{
	DUILog(DUILogTrace, @"%@ retained object", self);

	if (!_objectRetained && _object != nil)
	{
		CFRetain((__bridge CFTypeRef)(_object));
		_objectRetained = YES;
	}
}

// Release the object and unset the retained flag
- (void) releaseObject
{
	DUILog(DUILogTrace, @"%@ released object", self);
	
	if (_objectRetained)
	{
		CFRelease((__bridge CFTypeRef)(_object));
		_objectRetained = NO;
	}
}

// If previously retained the dealloc releases the stored object.
- (void)dealloc
{
	DUILog(DUILogTrace, @"%@ released", self);

	if (_objectRetained && _object != nil)
		CFRelease((__bridge CFTypeRef)(_object));
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@: %p; identifier = %@; %@; object = %@", [self class], self, self.identifier, self.objectIsRetained ? @"retained" : @"unretained", self.object];
}

@end


#pragma mark -
@implementation DUISharedSingletonObjectData

- (instancetype) initWithSelector:(SEL)selector identifier:(DUISingletonIdentifier *)identifier
{
	self = [super init];
	if (self)
	{
		_selector = selector;
		_identifier = identifier;
	}
	return self;
}

@end
