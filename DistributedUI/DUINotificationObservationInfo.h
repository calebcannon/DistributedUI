//
//  DUINotificationObserver.h
//  DistributedUI
//
//  Created by Caleb Cannon on 3/20/14.
//  Copyright (c) 2014 Caleb Cannon. All rights reserved.
//

@import Foundation;

@class DUIObjectIdentifier;

/**
 This class manages distributed notification data. We store the notification name, sender,
 receiver, and selector for remotely intercepted notifications. We subscribe to the
 notification locally and forward distributed notifications when they are received
*/

@interface DUINotificationObservationInfo : NSObject <NSCoding, NSCopying>

@property (readonly) NSString *name;
@property (readonly) DUIObjectIdentifier *objectIdentifier;
@property (readonly) DUIObjectIdentifier *observerIdentifier;
@property (readonly) SEL selector;

- (instancetype) initWithName:(NSString *)name objectIdentifier:(DUIObjectIdentifier *)objectIdentifier observerIdentifier:(DUIObjectIdentifier *)observerIdentifier selector:(SEL)selector;

@end
