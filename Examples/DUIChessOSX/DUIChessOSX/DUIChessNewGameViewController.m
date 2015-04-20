//
//  ViewController.m
//  DUIChessOSX
//
//  Created by Caleb Cannon on 4/11/15.
//  Copyright (c) 2015 Caleb Cannon. All rights reserved.
//

@import MultipeerConnectivity;

#import "DUIChessNewGameViewController.h"
#import "DUIChessManager.h"

@interface DUIChessNewGameViewController () <MCBrowserViewControllerDelegate>

@property (weak) MCBrowserViewController *browserViewController;

@end


@implementation DUIChessNewGameViewController

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction) host:(id)sender
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionEnded:) name:DUIManagerSessionEndedNotification object:nil];

	[[DUIManager sharedDUIManager] startDistributedInterfaceHostSession];
	[[DUIChessManager sharedInstance] newgame];

	[self presentChessViewController];
}

- (IBAction) connect:(id)sender
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(peerConnected:) name:DUIPeerDidConnect object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(peerDisconnected:) name:DUIPeerDidDisconnect object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionEnded:) name:DUIManagerSessionEndedNotification object:nil];

	DUIManager *manager = [DUIManager sharedDUIManager];

	[manager startDistributedInterfaceClientSession];
	MCBrowserViewController *browserViewController = [[MCBrowserViewController alloc] initWithServiceType:manager.serviceType session:manager.session];
	browserViewController.delegate = self;
	[self presentViewControllerAsSheet:browserViewController];
	self.browserViewController = browserViewController;
}

- (void) presentChessViewController
{
	[self performSegueWithIdentifier:@"PresentChessViewController" sender:self];
}

- (void) sessionEnded:(NSNotification *)notification
{
	if (self.presentedViewControllers.count > 0)
		[self dismissViewController:self.presentedViewControllers[0]];
}

- (void) peerConnected:(NSNotification *)notification
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[self dismissViewController:self.browserViewController];
		[self presentChessViewController];
	});
}

- (void) peerDisconnected:(NSNotification *)notification
{
	if (self.presentedViewControllers.count > 0)
		[self dismissViewController:self.presentedViewControllers[0]];
}

- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController;
{
	[self dismissViewController:self.browserViewController];
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController
{
	[self dismissViewController:self.browserViewController];
}

@end
