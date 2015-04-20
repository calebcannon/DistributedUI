//
//  DUIChessCrossDissolveSegue.m
//  DUIChessOSX
//
//  Created by Caleb Cannon on 4/11/15.
//  Copyright (c) 2015 Caleb Cannon. All rights reserved.
//

#import "DUIChessCrossDissolveSegue.h"

@interface DUIChessCrossDissolveSegue () <NSViewControllerPresentationAnimator>
@end


@implementation DUIChessCrossDissolveSegue

- (void)perform
{
	[self.sourceController presentViewController:self.destinationController
										animator:self];
}

- (void)animatePresentationOfViewController:(NSViewController *)viewController fromViewController:(NSViewController *)fromViewController
{
	[fromViewController insertChildViewController:viewController atIndex:0];
	
	viewController.view.wantsLayer = YES;
	viewController.view.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
	viewController.view.alphaValue = 0.0;
	viewController.view.frame = fromViewController.view.frame;
	
	[fromViewController.view addSubview:viewController.view];

	viewController.view.animator.alphaValue = 1.0;
}

- (void)animateDismissalOfViewController:(NSViewController *)viewController fromViewController:(NSViewController *)fromViewController
{
	[viewController removeFromParentViewController];
	
	viewController.view.wantsLayer = YES;
	viewController.view.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		viewController.view.animator.alphaValue = 0.0;
	} completionHandler:^{
		[viewController.view removeFromSuperview];
	}];
	
}

@end

