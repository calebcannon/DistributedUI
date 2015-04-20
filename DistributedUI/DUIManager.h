//
//  DUIManager.h
//  DistributedUI
//
//  Created by Caleb Cannon on 12/6/13.
//  Copyright (c) 2013 Caleb Cannon. All rights reserved.
//


@import Foundation;
@import MultipeerConnectivity;


@class DUIObjectProxy;
@class DUILocalObjectProxy;
@class DUIRemoteObjectProxy;
@class DUIManager;
@class DUIInvocation;
@class DUIIdentifier;
@class DUIObjectIdentifier;
@class DUIPeer;


/// Notifications

// Sent when a DUI service starts
extern NSString * const DUIManagerSessionStartedNotification;

/// Sent when a DUI service stops
extern NSString * const DUIManagerSessionEndedNotification;

/// Sent when a remote device connected as a client registers an object. The notification userInfo dictionary will contain a pointer to the proxy that can be used to pass messages to the remote object.
extern NSString * const DUIManagerDidRegisterObjectNotification;

/// Sent when a remote device connected as a client de-registers an object. Any pointers to to the represented proxy object should be invalidated.
extern NSString * const DUIManagerDidUnregisterObjectNotification;

/// Sent when available devices are discovered on the network. The userInfo dictionary contains a pointer to any newly discovered services and a flag indicating if more services have been discoverd
extern NSString * const DUIManagerFoundPeerNotification;

/// Sent when a device is removed from the network services. The userInfo dictionary contains a pointer to any newly discovered services and a flag indicating if more services have been discoverd
extern NSString * const DUIManagerDidRemoveServiceNotification;

// Notification userInfo keys
extern NSString * const kDUIManagerPeer;




/// These constants are used to specify the argument passing policy for remote invocations
/// TODO: policies are currently un-implemented
typedef NS_ENUM(NSUInteger, DUIArgumentPassingPolicy)
{
	DUIArgumentPassingPolicyCopy = 0,		// Objects not explicitly added to the remoteProxiedClasses array are copied by default
	DUIArgumentPassingPolicyProxy = 1,		// Objects not explicitely added to the remoteCopiedClasses are proxied by default
	
	DUIArgumentPassingPolicyDelegate = -1,	// The manager will query the argumentsDelegate for each object	
};


/// Objects that interface with the DUIManager may conform to the distributed object protocol
@protocol DUIDistrubtedObject <NSObject>
@end



/// The DUIManagerDelegate can be implemented to provide application level management of incoming connections
@protocol DUIManagerDelegate <NSObject>

@required
- (BOOL) duiManagerShouldAcceptConnectionFromPeer:(DUIPeer *)duiPeer;

@end



/**
 The DUIManager class is a singleton class that manages the connection for devices running as either hosts or clients.
 The manager is initialized using the [DUIManager sharedManager] method and a the Bonjour network services are
 started using the startDistributedInterfaceSession method. The manager will monitor for new connections and can
 automatically prompt for authentication using a pin code. Applications wishing to control the authentication
 process can implement the DUIManagerDelegate protocol to do so
 
 When sending and recieving remote invocations developers may wish to prevent certain objects from being transferred over
 the network. The remoteCopiedClasses and remoteProxiedClasses arrays can be used to explicitely control which types
 of objects are copied and which types of objects are proxied on the remote end. The argumentPassingPolicy controls the
 default argument passing behaviour
 */

#pragma mark -

@interface DUIManager : NSObject

/// Typically an application will only need one instance of a DUIManager
+ (instancetype) sharedDUIManager;

- (instancetype) initWithServiceType:(NSString *)serviceType info:(NSDictionary *)info;

/// The service type to be used by the multipeer-connectivity session.  If this value is changed during an active session a DUIException will be raised.
@property (strong) NSString *serviceType;
@property (readonly) MCSession *session;

/// If assigned the delegate must implement the DUIManagerDelegate protocol for responding to incoming connection events
@property (assign) id <DUIManagerDelegate> delegate;

/// Begin the DUI session as host. The DUI manager will advertise it's presence to nearby clients using MultiPeer Connectivity. Applications should request user permission before invoking this method.
- (void) startDistributedInterfaceHostSession;

/// Begin the DUI session as a client. The DUIManager will scan for nearby hosts and report to the delegate as they are found
- (void) startDistributedInterfaceClientSession;

/// Stops the DUI session. If the receiver is hosting the session all clients will be disconnected. Otherwise only the receiver will be disconnected.
- (void) stopDistributedInterfaceSession;

/// TRUE if the DUI session is active
@property (atomic, readonly, getter=isSessionActive) BOOL sessionActive;

/// Returns true if if this instance (Device) is the application host.
@property (atomic, readonly, getter=isHost) BOOL host;

/// Contains a list of currently discovered peers, including those the application has already connected to.  If the reciever is a host instance this method returns nil
@property (readonly, retain) NSArray *discoveredPeers;

/// Contains a list of connected peers.  If the reciever is a client instance the array contains only the host service
@property (readonly, retain) NSArray *connectedPeers;

/// Open the network connection for the peer
- (void) connectPeer:(DUIPeer *)peer;

/// Close the network connection
- (void) disconnectPeer:(DUIPeer *)peer;

/// Returns an array of proxies for remote objects.
@property (readonly) NSArray *remoteObjectProxies;

/// The argument passing policy. See @DUIArgumentPassingPolicy for options
@property (assign) DUIArgumentPassingPolicy argumentPassingPolicy;

/// An array of class names (NSStringFromClass) of objects that are automatically copied to the remote end during invocations and notifications
@property (copy) NSArray *remoteCopiedClassNames;

/// An array of class names (NSStringFromClass) of objects that are automatically proxied to the remote end during invocations and notifications
@property (copy) NSArray *remoteProxiedClassNames;

/// Add a remote object proxy
- (void) addRemoteObjectProxy:(DUIRemoteObjectProxy *)proxy;

/// Remove a remote object proxy
- (void) removeRemoteObjectProxy:(DUIRemoteObjectProxy *)proxy;

/// Returns the remote object proxy for the given idenifier
- (DUIRemoteObjectProxy *) remoteObjectProxyForIdentifier:(DUIIdentifier *)identifier;

/**
 This method sets up a given object as a distributed object. For each object added
 each remote device will initialize a DUObjectProxy for the given object. Messages
 sent to those proxies will be propogated to the actual object and return values
 will be propogated back. Proxies registered with this method are retained by
 strong reference. For safety, classes maintaining pointers to these proxies should
 use weak references.
 
 If retain is true the object is retained by the manager and will remain valid until
 it is removed from the registry using the removeDistributedObject: method. Otherwise
 the object will be removed from the registry when it is deallocated
 
 Returns the distributed object identifier for the newly registered object
 @param object The object to register for distributed invocations
 @param shouldRetain If TRUE, object will be retained by the receiver. Otherwise the object will be weakly referenced and removed from the registry automatically
 */
- (DUIObjectIdentifier *) addDistributedObject:(id)object retain:(BOOL)shouldRetain;
- (DUIObjectIdentifier *) addDistributedObject:(id)object withIdentifier:(DUIObjectIdentifier *)identifier retain:(BOOL)shouldRetain;

/**
 Removes the object from the distributed object registries and invalidates remote proxies for the given object.
 @param object The distributed object to remove. Must be previously registered using addDistributedObject:retain:
 */
- (void) removeDistributedObject:(id)object;

/// Removes all distributed objects
- (void) removeAllDistributedObjects;

/// Returns the number of registered objects.
@property (readonly) NSUInteger distributedObjectsCount;

/// Returns an array of currently resident distributed objects
@property (readonly) NSArray *distributedObjects;

@property (readonly) NSArray *distributedObjectIdentifiers;

/// Returns the distributed object for the given identifier. Returns nil if the identifier is invalid.
- (id) objectWithIdentifier:(DUIObjectIdentifier *)identifier;

/// Returns the network identifier for the given object. Returns nil if the object is not registered as a distributed object.
- (DUIObjectIdentifier *) identifierForObject:(id)object;

/**
 Adds a distributed notification observer. The method functions just like the NSNotification centers addObserver:selector:name:object method with
 the caveat that the observed object may be a remote object proxy. If the object is not a remote object proxy this method will subscribe
 the observer to the local notification for the observed object.
 */
- (void) addDistributedNotificationObserver:(id)observer selector:(SEL)selector name:(NSString *)name object:(id)object;

/**
 Posts a notification locally to the default notification center. This method is called when posting remotely recieved notifications
 in order to prevent a recursive observers must observer local and remote notifications having the same name.  Note that distributed 
 notifications are always posted to the main queueu.
 */
- (void) postLocalNotification:(NSNotification *)notification;

@end