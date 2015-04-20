//
//  AppDelegate.m
//  DUIChessOSX
//
//  Created by Caleb Cannon on 4/11/15.
//  Copyright (c) 2015 Caleb Cannon. All rights reserved.
//

#import "AppDelegate.h"

@import DistributedUI;
#import "DUIChessManager.h"


@implementation AppDelegate

- (IBAction) quitgame:(id)sender
{
	[[DUIManager sharedDUIManager] stopDistributedInterfaceSession];
}

- (IBAction) newgame:(id)sender
{
	[[DUIChessManager sharedInstance] newgame];
}

@end
