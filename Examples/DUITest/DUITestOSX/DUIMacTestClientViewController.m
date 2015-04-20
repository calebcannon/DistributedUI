//
//  DUIMacTestClientViewController.m
//  DUITest
//
//  Created by Caleb Cannon on 4/18/15.
//  Copyright (c) 2015 Caleb Cannon. All rights reserved.
//


@import DistributedUI;

#import "DUITestSingletonClass.h"
#import "DUIMacTestClientViewController.h"



@interface DUIMacTestClientViewController ()
@end



@implementation DUIMacTestClientViewController

- (void) viewWillAppear
{
	[super viewWillAppear];
	
	self.testObject = [DUITestSingletonClass sharedInstance];

	[self valuesChanged];
	
	[[DUIManager sharedDUIManager] addDistributedNotificationObserver:self selector:@selector(valuesChanged) name:DUITestTextValueChangedNotification object:nil];
	[[DUIManager sharedDUIManager] addDistributedNotificationObserver:self selector:@selector(valuesChanged) name:DUITestImageValueChangedNotification object:nil];
	[[DUIManager sharedDUIManager] addDistributedNotificationObserver:self selector:@selector(valuesChanged) name:DUITestFloatValueChangedNotification object:nil];
	[[DUIManager sharedDUIManager] addDistributedNotificationObserver:self selector:@selector(valuesChanged) name:DUITestIndexValueChangedNotification object:nil];
	[[DUIManager sharedDUIManager] addDistributedNotificationObserver:self selector:@selector(valuesChanged) name:DUITestSwitchValueChangedNotification object:nil];
}

- (void) valuesChanged
{
	
	if (self.testObject.textValue)
		self.textField.stringValue = self.testObject.textValue;
	
	self.imageView.image = self.testObject.imageValue;
	self.slider.floatValue = self.testObject.floatValue;
	NSUInteger index = self.testObject.indexValue;
	self.segmentedControl.selectedSegment = (index < 4) ? index : 0;
	self.toggleSwitch.state = (self.testObject.switchValue) ? NSOnState : NSOffState;
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

- (IBAction) textDidChange:(id)sender
{
	self.testObject.textValue = self.textField.stringValue;
}

- (IBAction) floatValueChanged:(id)sender
{
	self.testObject.floatValue = self.slider.floatValue;
}

- (IBAction) switchValueChanged:(id)sender
{
	self.testObject.switchValue = (self.toggleSwitch.state == NSOnState);
}

- (IBAction) indexValueChanged:(id)sender
{
	self.testObject.indexValue = self.segmentedControl.selectedSegment;
}

- (IBAction) selectImage:(id)sender
{
	[self.testObject setImageValue:self.imageView.image];
}

@end
