//
//  DUINotification.h
//  DistributedUI
//
//  Created by Caleb Cannon on 3/20/14.
//  Copyright (c) 2014 Caleb Cannon. All rights reserved.
//

@import Foundation;

@class DUIIdentifier;
@class DUIObjectIdentifier;


@interface DUINotification : NSObject <NSCopying, NSCoding>

/// Unique identifier for this notification object
@property (readonly) DUIIdentifier *identifier;

@property (readonly, copy) NSString *name;
@property (readonly, retain) id object;
@property (readonly, copy) NSDictionary *userInfo;

/// Object identifier for the notification sender
@property (readonly) DUIObjectIdentifier *objectIdentifier;

/// Create a instance of a DUI notification from an NSNotification
+ (instancetype) notificationWithNotification:(NSNotification *)notification;

/// Initialize a new DUI notification
- (instancetype) initWithName:(NSString *)name objectIdentifier:(DUIObjectIdentifier *)objectIdentifier userInfo:(NSDictionary *)userInfo;

/// Creates an NSNotification using the info stored in the DUINotification
- (NSNotification *) notification;

@end
