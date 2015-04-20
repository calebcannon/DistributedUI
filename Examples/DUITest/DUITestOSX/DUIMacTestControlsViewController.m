//
//  DUIMacTestControlsViewController.m
//  DUITest
//
//  Created by Caleb Cannon on 4/18/15.
//  Copyright (c) 2015 Caleb Cannon. All rights reserved.
//

#import "DUIMacTestControlsViewController.h"

@import DistributedUI;


@interface DUIMacTestControlsViewController () <MCBrowserViewControllerDelegate>
@end



@implementation DUIMacTestControlsViewController

- (void)viewDidAppear
{
	[super viewDidAppear];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(peerConnected:) name:DUIPeerDidConnect object:nil];
	
	[self updateControlStates];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)startHost:(id)sender
{
	[[DUIManager sharedDUIManager] startDistributedInterfaceHostSession];
	[self updateControlStates];
}

- (IBAction)startClient:(id)sender
{
	[[DUIManager sharedDUIManager] startDistributedInterfaceClientSession];
	[self updateControlStates];
}

- (IBAction)browse:(id)sender
{
	MCBrowserViewController *browser = [[MCBrowserViewController alloc] initWithServiceType:[DUIManager sharedDUIManager].serviceType session:[DUIManager sharedDUIManager].session];
	browser.delegate = self;
	[self presentViewControllerAsSheet:browser];

	[self updateControlStates];
}

- (void) peerConnected:(NSNotificationCenter *)defaultCenter
{
	dispatch_async(dispatch_get_main_queue(), ^{
		if (self.presentedViewControllers.count > 0)
			[self dismissViewController:self.presentedViewControllers[0]];
		[self updateControlStates];
	});
}

- (IBAction)stop:(id)sender
{
	[[DUIManager sharedDUIManager] stopDistributedInterfaceSession];
	[self updateControlStates];
}

- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController
{
	dispatch_async(dispatch_get_main_queue(), ^{
		if (self.presentedViewControllers.count > 0)
			[self dismissViewController:self.presentedViewControllers[0]];
		[self updateControlStates];
	});
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController
{
	dispatch_async(dispatch_get_main_queue(), ^{
		if (self.presentedViewControllers.count > 0)
			[self dismissViewController:self.presentedViewControllers[0]];
		[self updateControlStates];
	});
}

- (void) updateControlStates
{
	NSAssert([[NSThread currentThread] isMainThread], @"Main thread only plz");
	
	if (![DUIManager sharedDUIManager].isSessionActive)
	{
		self.hostStatusLabel.stringValue = @"Not Connected";
		self.clientStatusLabel.stringValue = @"Not Connected";
		self.startClientButton.enabled = YES;
		self.startHostButton.enabled = YES;
		self.testClientButton.enabled = NO;
		self.testHostButton.enabled = NO;
		self.browseButton.enabled = NO;
		self.stopClientButton.enabled = NO;
		self.stopHostButton.enabled = NO;
	}
	else
	{
		if ([[DUIManager sharedDUIManager] isHost])
		{
			self.hostStatusLabel.stringValue = @"Started";
			self.clientStatusLabel.stringValue = @"Unavailable";
			self.browseButton.enabled = NO;
			self.testClientButton.enabled = NO;
			self.testHostButton.enabled = YES;
			self.stopClientButton.enabled = NO;
			self.stopHostButton.enabled = YES;
		}
		else
		{
			self.hostStatusLabel.stringValue = @"Unavailable";
			self.clientStatusLabel.stringValue = @"Started";
			self.browseButton.enabled = YES;
			self.stopClientButton.enabled = YES;
			self.stopHostButton.enabled = NO;
			self.testClientButton.enabled = ([[DUIManager sharedDUIManager] connectedPeers].count > 0);
			self.testHostButton.enabled = NO;
		}
		
		self.startClientButton.enabled = NO;
		self.startHostButton.enabled = NO;
	}
}
@end
