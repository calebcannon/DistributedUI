//
//  DUIChessViewController.m
//  DUIChess
//
//  Created by Caleb Cannon on 3/19/14.
//  Copyright (c) 2014 Caleb Cannon. All rights reserved.
//

@import DistributedUI;

#import "DUIChessViewController.h"


@implementation DUIChessViewController

- (void) viewDidAppear:(BOOL)animated
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionEnded:) name:DUIManagerSessionEndedNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) sessionEnded:(NSNotification *)notification
{
	[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction) quit:(id)sender
{
	[[DUIManager sharedDUIManager] stopDistributedInterfaceSession];
	[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
