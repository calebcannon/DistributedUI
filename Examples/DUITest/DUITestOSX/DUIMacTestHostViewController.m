//
//  DUIMacTestHostViewController.m
//  DUITest
//
//  Created by Caleb Cannon on 4/18/15.
//  Copyright (c) 2015 Caleb Cannon. All rights reserved.
//

@import DistributedUI;

#import "DUITestSingletonClass.h"
#import "DUIMacTestHostViewController.h"

@interface DUIMacTestHostViewController ()

@end



@implementation DUIMacTestHostViewController

- (void)viewDidLoad
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textValueChanged:) name:DUITestTextValueChangedNotification object:self.testObject];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageValueChanged:) name:DUITestImageValueChangedNotification object:self.testObject];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(floatValueChanged:) name:DUITestFloatValueChangedNotification object:self.testObject];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(indexValueChanged:) name:DUITestIndexValueChangedNotification object:self.testObject];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(switchValueChanged:) name:DUITestSwitchValueChangedNotification object:self.testObject];
}

- (void) viewWillAppear
{
	[super viewWillAppear];
	
	self.testObject = [DUITestSingletonClass sharedInstance];

	// Set current values for all controls
	if (self.testObject.textValue)
		self.textLabel.stringValue = self.testObject.textValue;
	self.imageView.image = self.testObject.imageValue;
	self.progressView.doubleValue = self.testObject.floatValue * 100;
	[self.pageControl selectCell:self.pageControl.cells[self.testObject.indexValue]];
	if (self.testObject.switchValue)
		[self.activityIndicator startAnimation:self];
	else
		[self.activityIndicator stopAnimation:self];
}

- (void)viewDidAppear
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionEnded:) name:DUIManagerSessionEndedNotification object:nil];
}

- (void) viewWillDisappear
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) sessionEnded:(NSNotification *)notification
{
	[self.view.window close];
}

- (void) textValueChanged:(NSNotification *)notification
{
	self.textLabel.stringValue = self.testObject.textValue;
}

- (void) imageValueChanged:(NSNotification *)notification
{
	self.imageView.image = self.testObject.imageValue;
}

- (void) floatValueChanged:(NSNotification *)notification
{
	self.progressView.doubleValue = self.testObject.floatValue * 100;
}

- (void) indexValueChanged:(NSNotification *)notification
{
	[self.pageControl deselectAllCells];
	[self.pageControl selectCell:self.pageControl.cells[self.testObject.indexValue]];
}

- (void) switchValueChanged:(NSNotification *)notification
{
	if (self.testObject.switchValue)
		[self.activityIndicator startAnimation:self];
	else
		[self.activityIndicator stopAnimation:self];
}

@end
