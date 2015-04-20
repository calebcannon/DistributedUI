//
//  DUIInvocationResponse.h
//  DistributedUI
//
//  Created by Caleb Cannon on 12/28/13.
//  Copyright (c) 2013 Caleb Cannon. All rights reserved.
//

@import Foundation;

@class DUIIdentifier;
@class DUIInvocation;

@interface DUIInvocationResponse : NSObject <NSCoding>

/// The identifier of the invocation from which the response is taken
@property (readonly) DUIIdentifier *invocationIdentifier;

/// The response (return value) data of the invocation
@property (readonly) NSData *responseData;

+ (instancetype) invocationResponseWithIdentifier:(DUIIdentifier *)identifier responseData:(NSData *)responseData;
- (instancetype) initWithIdentifier:(DUIIdentifier *)identifier responseData:(NSData *)data;

+ (instancetype) invocationResponseWithInvocation:(DUIInvocation *)invocation;
- (void) setForInvocation:(DUIInvocation *)invocation;


@end
