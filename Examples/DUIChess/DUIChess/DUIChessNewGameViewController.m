//
//  DUINewGameViewController.m
//  DUIChess
//
//  Created by Caleb Cannon on 3/19/14.
//  Copyright (c) 2014 Caleb Cannon. All rights reserved.
//

@import DistributedUI;

#import "DUIChessNewGameViewController.h"
#import "DUIChessViewController.h"
#import "DUIChessManager.h"



@implementation DUIChessNewGameViewController

- (IBAction)host:(id)sender
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[[DUIManager sharedDUIManager] startDistributedInterfaceHostSession];

	[[DUIChessManager sharedInstance] newgame];

	[self presentChessViewController];
}

- (IBAction)connect:(id)sender
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clientConnected:) name:DUIPeerDidConnect object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clientDisconnected:) name:DUIPeerDidDisconnect object:nil];

	[[DUIManager sharedDUIManager] startDistributedInterfaceClientSession];

	DUIManager *manager = [DUIManager sharedDUIManager];

	MCBrowserViewController *browser = [[MCBrowserViewController alloc] initWithServiceType:manager.serviceType session:manager.session];
	browser.delegate = self;
	[self presentViewController:browser animated:YES completion:nil];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) presentChessViewController
{
	if (self.presentedViewController)
		[self dismissViewControllerAnimated:YES completion:nil];
	
	[self performSegueWithIdentifier:@"PresentChessView" sender:self];
}

- (void) clientConnected:(NSNotification *)notification
{
	// Hide the pairing view and present the chess view
	dispatch_async(dispatch_get_main_queue(), ^{
		[self dismissViewControllerAnimated:YES completion:^{
			[self presentChessViewController];
		}];
	});
}

- (void) clientDisconnected:(NSNotification *)notification
{
	// Present the chess view
	dispatch_async(dispatch_get_main_queue(), ^{
		[self dismissViewControllerAnimated:YES completion:nil];
	});
}

- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController;
{
	// Hide the pairing view controller
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController
{
	// Hide the pairing view controller
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
