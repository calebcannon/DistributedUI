//
//  DUIInvocation.h
//  DistributedUI
//
//  Created by Caleb Cannon on 12/17/13.
//  Copyright (c) 2013 Caleb Cannon. All rights reserved.
//

@import Foundation;

@class DUIIdentifier, DUIObjectIdentifier;

@interface DUIInvocation : NSObject <NSCoding, NSCopying>

/// The identifier for this invocation. Generated during initialization
@property (readonly) DUIIdentifier *identifier;

/// The global identifier of the target object (see [DUIManager addDistributedObject:retain:])
@property (readonly) DUIObjectIdentifier *objectIdentifier;

/// The invocation to invoke against the target object. When invoked remotely, certain arguments may be substituted with additional proxies depending on the argument transmission policies of the DUIManger
@property (readonly) NSInvocation *invocation;

/// When this invocation is executed by a client the response semaphore is used to block on the execution queue until the invocation response is received from the host
@property (readonly) dispatch_semaphore_t response_semaphore;

/// Initialize a new distributed invocation object
- (instancetype) initWithInvocation:(NSInvocation *)invocation identifier:(DUIObjectIdentifier *)identifer responseSempahore:(dispatch_semaphore_t)response_semaphore;


@end
