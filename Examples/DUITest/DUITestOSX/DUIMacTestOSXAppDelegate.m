//
//  DUIMacTestOSXAppDelegate.m
//  DUITestOSX
//
//  Created by Caleb Cannon on 12/7/13.
//  Copyright (c) 2013 Caleb Cannon. All rights reserved.
//

#import "DUIMacTestOSXAppDelegate.h"
@import DistributedUI;


@implementation DUIMacTestOSXAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[DUIManager sharedDUIManager].serviceType = @"DUITest";
}

@end
