//
//  DUIViewController.m
//  DUIDraw
//
//  Created by Caleb Cannon on 3/28/14.
//  Copyright (c) 2014 Caleb Cannon. All rights reserved.
//

@import DistributedUI;

#import "DUIDrawViewController.h"
#import "DUIDraw.h"


@interface DUIDrawViewController ()

@end


@implementation DUIDrawViewController

- (void)viewWillAppear:(BOOL)animated
{
	if (![DUIManager sharedDUIManager].isHost || ![DUIManager sharedDUIManager].isSessionActive)
	{
		[[DUIManager sharedDUIManager] startDistributedInterfaceHostSession];
	}
	
	[[DUIManager sharedDUIManager] addDistributedNotificationObserver:self selector:@selector(colorChanged:) name:DUIDrawColorChangedNotification object:nil];
	[[DUIManager sharedDUIManager] addDistributedNotificationObserver:self selector:@selector(sizeChanged:) name:DUIDrawPenChangedNotification object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionsChanged:) name:DUIPeerDidConnect object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionsChanged:) name:DUIPeerDidDisconnect object:nil];

	// Navigation item let's us brow
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Tools" style:UIBarButtonItemStyleDone target:self action:@selector(showTools:)];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) connectionsChanged:(NSNotification *)notification
{
	// If we have a tool pallete connected hide the nav bar to give the canvas more space
	dispatch_async(dispatch_get_main_queue(), ^{
		BOOL shouldHidNavBar = [[[DUIManager sharedDUIManager] connectedPeers] count] > 0;
		[self.navigationController setNavigationBarHidden:shouldHidNavBar animated:YES];
	});
}

- (void) showTools:(id)sender
{
	[self performSegueWithIdentifier:@"PresentTools" sender:self];
}

- (void) colorChanged:(NSNotification *)notification
{
	UIColor *color = [notification.userInfo objectForKey:@"color"];
	if (color)
		self.drawView.penColor = color;
}

- (void) sizeChanged:(NSNotification *)notification
{
	NSNumber *number = [notification.userInfo objectForKey:@"size"];
	if (number)
		self.drawView.penSize = number.floatValue;
}

@end
