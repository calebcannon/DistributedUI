//
//  DFirstViewController.m
//  DUITest
//
//  Created by Caleb Cannon on 12/6/13.
//  Copyright (c) 2013 Caleb Cannon. All rights reserved.
//

#import "DUITestControlsViewController.h"

@import DistributedUI;



@implementation DUITestControlsViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(peerConnected:) name:DUIPeerDidConnect object:nil];
	//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(peerDisconnected:) name:DUIPeerDidDisconnect object:nil];

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
	[self presentViewController:browser animated:YES completion:nil];
	[self updateControlStates];
}

- (void) peerConnected:(NSNotificationCenter *)defaultCenter
{
	[self dismissViewControllerAnimated:YES completion:nil];

}

- (IBAction)stop:(id)sender
{
	[[DUIManager sharedDUIManager] stopDistributedInterfaceSession];
	[self updateControlStates];
}

- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void) updateControlStates
{
	if (![DUIManager sharedDUIManager].isSessionActive)
	{
		self.hostStatusLabel.text = @"Not Connected";
		self.clientStatusLabel.text = @"Not Connected";
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
			self.hostStatusLabel.text = @"Started";
			self.clientStatusLabel.text = @"Unavailable";
			self.browseButton.enabled = NO;
			self.testClientButton.enabled = NO;
			self.testHostButton.enabled = YES;
			self.stopClientButton.enabled = NO;
			self.stopHostButton.enabled = YES;
		}
		else
		{
			self.hostStatusLabel.text = @"Unavailable";
			self.clientStatusLabel.text = @"Started";
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

