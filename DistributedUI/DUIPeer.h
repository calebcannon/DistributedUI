//
//  DUIPeer.h
//  DistributedUI
//
//  Created by Caleb Cannon on 4/8/15.
//  Copyright (c) 2015 Caleb Cannon. All rights reserved.
//

#import "DistributedUI.h"

@import Foundation;
@import MultipeerConnectivity;

@class DUIInvocationResponse;
@class DUINotification;
@class DUINotificationObservationInfo;



/// Notification posted when the peer connects to the host
extern NSString * const DUIPeerDidConnect;

/// Notification posted when a peer disconnected from the host
extern NSString * const DUIPeerDidDisconnect;

/// Notification posted when an async remote invocation is invoked successully
extern NSString * const DUIPeerDidExecuteRemoteInvocation;

/// Notification posted when an async remote invocation fails to invoke
extern NSString * const DUIPeerDidFailToExecuteRemoteInvocation;

/// userInfo key for the DUINetServiceDidExecuteRemoteInvocation and DUINetServiceDidFailToExecuteRemoteInvocation notifications
extern NSString * const kDUIInvocation;




@protocol DUIPeerDelegate <NSObject>

- (void) duiPeerDidAcceptConnection:(DUIPeer *)duiPeer;

- (void) duiPeer:(DUIPeer *)duiPeer didReceiveRemoteInvocation:(DUIInvocation *)invocation;
- (void) duiPeer:(DUIPeer *)duiPeer didReceiveRemoteInvocationResponse:(DUIInvocationResponse *)response;
- (void) duiPeer:(DUIPeer *)duiPeer didReceiveRemoteObjectRegistration:(DUIObjectIdentifier *)identifier;

- (void) duiPeer:(DUIPeer *)duiPeer didReceiveRemoteNotificationObservationInfo:(DUINotificationObservationInfo *)observer;
- (void) duiPeer:(DUIPeer *)duiPeer didReceiveRemoteNotification:(DUINotification *)notification;

- (void) duiPeer:(DUIPeer *)duiPeer willForwardDistributedInvocation:(DUIInvocation *)invocation;
- (void) duiPeer:(DUIPeer *)duiPeer didForwardDistributedInvocation:(DUIInvocation *)invocation;

@end


typedef NS_ENUM(NSUInteger, DUIPeerState)
{
	DUIPeerStateAvailable,
	DUIPeerStateConnecting,
	DUIPeerStateConnected,
	DUIPeerStateDisconnecting,
	DUIPeerStateUnavailable,
};

NSString *NSStringFromDUIPeerState(DUIPeerState state);



#pragma mark -

/**
 DUIPeers represent an instance of a remote peer.  Each device in the session maintains it's own list of connected peers, although the host device is responsible for
 the majority of the session coordination.
*/
@interface DUIPeer : NSObject

/// Initialize with a peer id.
- (instancetype) initWithPeerID:(MCPeerID *)peerID info:(NSDictionary *)info manager:(DUIManager *)manager;

/// Discovery info associated with the peer
@property (readonly) NSDictionary *info;

/// The peer connection ID of the service
@property (readonly, strong) MCPeerID *peerID;

/// The state of the peer
@property (readonly) DUIPeerState state;

/// Forward the invocation to the client hosting the object represented by objectProxy. Returns true if the invocation was sent and a response received successfully
- (BOOL) forwardInvocation:(NSInvocation *)invocation forProxy:(DUIRemoteObjectProxy *)objectProxy;

/// Forward the distributed invocation to the client hosting the object represented by objectProxy. When a response is received the net service will post the
/// DUINetServiceDidExecuteRemoteInvocation notification with a DUIInvocation as the kDUIInvocation key of the userInfo dictionary. If @timeOut seconds elapses
/// before a reponse is received the DUINetServiceDidFailToExecuteRemoteInvocation notificaiton is posted. If timeOut is 0 the invocation is forwarded synchronously
/// and the notifications are posted before the function returns
- (void) forwardInvocationAsync:(NSInvocation *)invocation forProxy:(DUIRemoteObjectProxy *)objectProxy timeout:(NSTimeInterval)timeOut;

/// Called by the DUIManager after a remote invocation is invoked. Do not execute directly
- (void) forwardResultForInvocation:(DUIInvocation *)duiInvocation;

/// Send an object to the peer,  When received, the remote peer will reconstruct the object and call one of it's delegate methods
- (BOOL) sendObject:(id<NSCoding>)anObject;
- (BOOL) sendData:(NSData *)data;

- (void) reconstructData:(NSData *)data;

@end

