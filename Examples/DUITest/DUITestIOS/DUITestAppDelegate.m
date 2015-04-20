//
//  DAppDelegate.m
//  DUITest
//
//  Created by Caleb Cannon on 12/6/13.
//  Copyright (c) 2013 Caleb Cannon. All rights reserved.
//

#import "DUITestAppDelegate.h"

@import DistributedUI;

@implementation DUITestAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[DUIManager sharedDUIManager].serviceType = @"DUITest";
    return YES;
}

@end
