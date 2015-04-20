//
//  XCTestAsync.m
//  DistributedUI
//
//  Created by Caleb Cannon on 3/14/14.
//  Copyright (c) 2014 Caleb Cannon. All rights reserved.
//

#import "XCTestAsync.h"

@implementation XCTNotificationHandler

@synthesize didReceiveNotification = _didReceiveNotification;

- (instancetype) initWithNotificationName:(NSString *)name object:(id)object
{
	self = [super init];
	if (self)
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationReceived:) name:name object:object];
	}
	return self;
}

- (void) notificationReceived:(NSNotification *)notification
{
	NSLog(@"Notification received: %@", notification.name);
	_didReceiveNotification = YES;
}

@end