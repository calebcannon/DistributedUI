//
//  DUObjectProxy.h
//  DistributedUI
//
//  Created by Caleb Cannon on 12/6/13.
//  Copyright (c) 2013 Caleb Cannon. All rights reserved.
//


@import Foundation;


@class DUIPeer;
@class DUIObjectIdentifier;


/*
 Base class for DUI Proxy objects. The two subclasses are DUIRemoteObjectProxy and DUILocalObjectProxy.
 When the local object proxy receives an invocation is forwards the method to the represented object
 and then passes the result back to the caller via the DUIManager. Conversely, when remote
 objects receive an invocation the invocation is forwarded to the remote end via the DUIManager

 Instances of the concrete object proxy classes must be initialized using their designated initalizer
 methods. When initialized, local objects are added the the DUIManagers registry of local object
 proxys.
*/

@interface DUIRemoteObjectProxy : NSProxy

/// Initialize a proxy for a remote object. The identifier must be the valid identifier of a proxy
/// created using the initWithTarget:service: method.
- (instancetype) initWithIdentifier:(DUIObjectIdentifier *)identifier peer:(DUIPeer *)peer;

/// The class of the represented object
@property (weak, readonly) Class targetClass;

/// The netservice object that is used to transmit data for this proxy
@property (retain, readonly) DUIPeer *peer;

/// The identifier used to identify the concrete instance of the represented object on the remote end
@property (retain, readonly) DUIObjectIdentifier *identifier;

/// True if this proxy is valid. That is, messages sent to the proxy will be propogated over the network to
/// the represented object, and the value returned if provided
@property (readonly) BOOL isValid;

@end