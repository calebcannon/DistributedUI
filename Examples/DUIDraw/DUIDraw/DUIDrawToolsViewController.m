//
//  DUIDrawToolsViewController.m
//  DUIDraw
//
//  Created by Caleb Cannon on 3/28/14.
//  Copyright (c) 2014 Caleb Cannon. All rights reserved.
//

@import DistributedUI;
@import MultipeerConnectivity;

#import "DUIDrawToolsViewController.h"
#import "DUIDraw.h"
#import "DUIColorPickerView.h"


@interface DUIDrawToolsViewController () <MCBrowserViewControllerDelegate>
@end


@implementation DUIDrawToolsViewController

- (void)viewWillAppear:(BOOL)animated
{
	if (![DUIManager sharedDUIManager].isSessionActive)
		[[DUIManager sharedDUIManager] startDistributedInterfaceClientSession];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismissViewController:) name:DUIPeerDidDisconnect object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
	if (![DUIManager sharedDUIManager].isHost && [[DUIManager sharedDUIManager] connectedPeers].count == 0)
	{
		MCBrowserViewController *browser = [[MCBrowserViewController alloc] initWithServiceType:[DUIManager sharedDUIManager].serviceType session:[DUIManager sharedDUIManager].session];
		browser.delegate = self;
		[self presentViewController:browser animated:YES completion:nil];
	}
}

- (void) dismissViewController:(NSNotification *)notification
{
	[[DUIManager sharedDUIManager] stopDistributedInterfaceSession];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.navigationController popViewControllerAnimated:YES];
	});
}

- (void)viewDidDisappear:(BOOL)animated
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction) changeColor:(DUIColorPickerView *)sender
{
	UIColor *color = sender.color;
	NSDictionary *userInfo = @{ @"color" : color };
	[[NSNotificationCenter defaultCenter] postNotificationName:DUIDrawColorChangedNotification object:self userInfo:userInfo];
}

- (IBAction) changeBrushSize:(UISlider *)sender
{
	NSNumber *size = [NSNumber numberWithFloat:sender.value];
	NSDictionary *userInfo = @{ @"size" : size };
	[[NSNotificationCenter defaultCenter] postNotificationName:DUIDrawPenChangedNotification object:self userInfo:userInfo];
}

- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController;
{
	if ([[DUIManager sharedDUIManager] connectedPeers].count == 0)
		return;

	// Hide the pairing view controller
	[self dismissViewControllerAnimated:YES completion:^{
		[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
	}];
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController
{
	if ([[DUIManager sharedDUIManager] connectedPeers].count == 0)
		return;

	// Hide the pairing view controller
	[self dismissViewControllerAnimated:YES completion:^{
		[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
	}];
}

@end
