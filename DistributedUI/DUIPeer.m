//
//  DUIPeer.m
//  DistributedUI
//
//  Created by Caleb Cannon on 4/8/15.
//  Copyright (c) 2015 Caleb Cannon. All rights reserved.
//

#import "DUIPeer.h"

NSString * const DUIPeerDidConnect = @"DUIPeerDidConnect";
NSString * const DUIPeerDidDisconnect = @"DUIPeerDidDisconnect";
NSString * const DUIPeerDidExecuteRemoteInvocation = @"DUIPeerDidExecuteRemoteInvocation";
NSString * const DUIPeerDidFailToExecuteRemoteInvocation = @"DUIPeerDidFailToExecuteRemoteInvocation";
NSString * const kDUIInvocation = @"kDUIInvocation";


@interface DUIPeer ()

@property (readonly) dispatch_queue_t invocation_response_queue;

@property (strong) NSMapTable *invocations;

@property (readonly) DUIManager *manager;

/// The encoder used to encode data sent to peers.  This encoder must conform to the NSCoding and 
@property (strong) NSCoder *encoder;

@end



@interface DUIManager ()

- (void) duiPeer:(DUIPeer *)peer didReceiveRemoteObjectRegistration:(DUIObjectIdentifier *)objectIdentifier;
- (void) duiPeer:(DUIPeer *)peer didReceiveRemoteInvocation:(DUIInvocation *)duiInvocation;
- (void) duiPeer:(DUIPeer *)duiPeer didReceiveRemoteNotificationObservationInfo:(DUINotificationObservationInfo *)observer;
- (void) duiPeer:(DUIPeer *)duiPeer didReceiveRemoteNotification:(DUINotification *)notification;
- (void) duiPeer:(DUIPeer *)peer didReceiveRemoteInvocationResponse:(DUIInvocationResponse *)response forInvocation:(DUIInvocation *)invocation;

@end





@implementation DUIPeer

- (instancetype) initWithPeerID:(MCPeerID *)peerID info:(NSDictionary *)info manager:(DUIManager *)manager
{
	self = [super init];
	if (self)
	{
		_peerID = peerID;
		_info = [info copy];
		_manager = manager;
		
		_invocations = [NSMapTable strongToStrongObjectsMapTable];
		_invocation_response_queue = dispatch_queue_create("invocation_response_queue", DISPATCH_QUEUE_CONCURRENT);
	}
	
	return self;
}

- (BOOL) forwardInvocation:(NSInvocation *)invocation forProxy:(DUIRemoteObjectProxy *)objectProxy
{
	// Create the remote invocation
	dispatch_semaphore_t invocation_semaphore = dispatch_semaphore_create(0);
	DUIInvocation *duiInvocation = [[DUIInvocation alloc] initWithInvocation:invocation identifier:objectProxy.identifier responseSempahore:invocation_semaphore];

	DUILog(DUILogDebug, @"forwarding invocation %@ for object %@", duiInvocation, [objectProxy description]);
	
	//[self.manager duiPeer:self willForwardDistributedInvocation:duiInvocation];

	// Archive as NSData and send. Inform the delegate of our progress
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:duiInvocation];
	
	BOOL sent = [self sendData:data];
	
	// TODO: inform someone of send error
	if (!sent)
		[NSException raise:DUIException format:@"Failed to send invocation"];

	assert(sent);
	
	// We've now sent the invocation and we need to bpo duilock until a response is received.  Here we're going to spin of a block that will
	// monitor the response queue until the a response with the identifier of the invocation we just sent shows up.  The semaphore
	// blocks this method from returning until a response is received or the we hit the timeout
	[self.invocations setObject:duiInvocation forKey:duiInvocation.identifier];
	
	const int64_t timeout_interval = 30;
	BOOL timed_out = dispatch_semaphore_wait(invocation_semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout_interval * NSEC_PER_SEC)));

	// Remove the invocation from the active list
	[self.invocations setObject:nil forKey:duiInvocation.identifier];

	if (timed_out)
	{
		// TODO: Inform someone a timeout error occurred
		//assert(0);
		// [self.manager duiPeer:self didForwardDistributedInvocation:duiInvocation];
	}
	
	return !timed_out;

}

- (void) forwardInvocationAsync:(NSInvocation *)invocation forProxy:(DUIRemoteObjectProxy *)objectProxy timeout:(NSTimeInterval)timeOut
{
	// Create the dispatch queue for async invocations
	static dispatch_queue_t forward_invocation_queue;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		forward_invocation_queue = dispatch_queue_create("forward_invocation_queue", 0);
	});
	
	// TODO: Send the notification asyncrosouly and cancel after the timeOut interval.
	dispatch_async(forward_invocation_queue, ^{
		
		// TODO: Remove and implement correctly. This method should use a operation queue or the like and be cancellable
		BOOL executed = [self forwardInvocation:invocation forProxy:objectProxy];
		
		if (executed)
			[[NSNotificationCenter defaultCenter] postNotificationName:DUIPeerDidExecuteRemoteInvocation object:self userInfo:@{ kDUIInvocation: invocation }];
		else
			[[NSNotificationCenter defaultCenter] postNotificationName:DUIPeerDidFailToExecuteRemoteInvocation object:self userInfo:@{ kDUIInvocation: invocation }];
	});
}

- (void) forwardResultForInvocation:(DUIInvocation *)duiInvocation
{
	DUIInvocationResponse *response = [DUIInvocationResponse invocationResponseWithInvocation:duiInvocation];
	[self sendObject:response];
}

#pragma mark - Send and receive operations

- (BOOL) sendObject:(id<NSCoding>)anObject
{
	DUILog(DUILogDebug, @"%@ sending object: %@", self, anObject);
	
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:anObject];
	BOOL sent = [self sendData:data];
	
	if (!sent)
	{
		DUILog(DUILogError, @"%@ could not send object %@", self, anObject);
		// TODO: Be more appropriate with the exceptions
		[NSException raise:@"Network Error" format:@"Could not send object"];
	}
	
	return sent;
}

- (BOOL) sendData:(NSData *)data
{
	DUILog(DUILogDebug, @"%@ sending %lu bytes", self, (unsigned long)data.length);
	DUILog(DUILogTrace, @"%@ sending %@", self, data);

	NSError *error = nil;
	[self.manager.session sendData:data toPeers:@[ self.peerID ] withMode:MCSessionSendDataReliable error:&error];
	if (error)
	{
		DUILog(DUILogError, @"%@ error sending data: %@", self, error);
		return NO;
	}
	
	return YES;
}

- (BOOL) sendBytes:(const void *)bytes length:(NSUInteger)length
{
	return NO;	
}

- (void) reconstructData:(NSData *)data
{
	@try
	{
		id object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
		
		if ([object isKindOfClass:[DUIInvocation class]])
			[self.manager duiPeer:self didReceiveRemoteInvocation:object];
		
		else if ([object isKindOfClass:[DUIObjectIdentifier class]])
			[self.manager duiPeer:self didReceiveRemoteObjectRegistration:object];
		
		else if ([object isKindOfClass:[DUINotificationObservationInfo class]])
			[self.manager duiPeer:self didReceiveRemoteNotificationObservationInfo:object];
		
		else if ([object isKindOfClass:[DUINotification class]])
			[self.manager duiPeer:self didReceiveRemoteNotification:object];
		
		else if ([object isKindOfClass:[DUIInvocationResponse class]])
		{
			DUIInvocationResponse *response = object;
			DUIInvocation *invocation = [self.invocations objectForKey:response.invocationIdentifier];

			[self.manager duiPeer:self didReceiveRemoteInvocationResponse:object forInvocation:invocation];
			
			dispatch_semaphore_signal(invocation.response_semaphore);
		}
		else
		{
			if (object == nil)
				DUILog(DUILogDebug, @"%@ couldn't decode object with data: %@", self, data);
			else
				DUILog(DUILogDebug, @"%@ received unexpected object: %@", self, object);
		}
	}
	@catch (NSException *exception)
	{
		DUILog(DUILogDebug, @"%@ couldn't reconstruct object: %@", self, exception);
	}
	@finally
	{
	}
}

@end


NSString *NSStringFromDUIPeerState(DUIPeerState state)
{
	switch (state) {
		case DUIPeerStateAvailable:
			return @"DUIPeerStateAvailable";
		case DUIPeerStateConnecting:
			return @"DUIPeerStateConnecting";
		case DUIPeerStateConnected:
			return @"DUIPeerStateConnected";
		case DUIPeerStateDisconnecting:
			return @"DUIPeerStateDisconnecting";
		case DUIPeerStateUnavailable:
			return @"DUIPeerStateUnavailable";
		default:
			return @"unknown/invalid";
	}
}