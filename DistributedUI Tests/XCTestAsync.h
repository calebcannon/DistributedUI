//
//  XCTestAsync.h
//  DistributedUI
//
//  Created by Caleb Cannon on 3/14/14.
//  Copyright (c) 2014 Caleb Cannon. All rights reserved.
//

@import Foundation;

#import <XCTest/XCTest.h>

@interface XCTNotificationHandler : NSObject

@property (readonly) BOOL didReceiveNotification;

- (instancetype) initWithNotificationName:(NSString *)name object:(id)object;
- (void) notificationReceived:(NSNotification *)notification;

@end


#define XCTAssertNotificationReceived(name, sender, duration, format, ...) \
({ \
	XCTNotificationHandler *handler = [[XCTNotificationHandler alloc] initWithNotificationName:name object:sender]; \
	NSTimeInterval restInterval = [[NSDate date] timeIntervalSinceReferenceDate] + duration; \
	while ([[NSDate date] timeIntervalSinceReferenceDate] < restInterval) \
	{ \
		if (handler.didReceiveNotification) \
		{ \
			[[NSNotificationCenter defaultCenter] removeObserver:handler]; \
			break; \
		} \
		NSDate *dt = [NSDate dateWithTimeIntervalSinceNow:0.1]; \
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:dt]; \
    } \
	if (!handler.didReceiveNotification) \
	{ \
		[[NSNotificationCenter defaultCenter] removeObserver:handler]; \
		_XCTRegisterFailure(_XCTFailureDescription(_XCTAssertion_Nil, 0, @#name),format); \
	} \
})