//
//  DUIMacTestClientViewController.h
//  DUITest
//
//  Created by Caleb Cannon on 4/18/15.
//  Copyright (c) 2015 Caleb Cannon. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DUIMacTestClientViewController : NSViewController

@property (strong) IBOutlet DUITestSingletonClass *testObject;

@property (strong) IBOutlet NSTextField *textField;
@property (strong) IBOutlet NSImageView *imageView;
@property (strong) IBOutlet NSSlider *slider;
@property (strong) IBOutlet NSButton *toggleSwitch;
@property (strong) IBOutlet NSSegmentedControl *segmentedControl;

- (IBAction) textDidChange:(id)sender;
- (IBAction) selectImage:(id)sender;
- (IBAction) floatValueChanged:(id)sender;
- (IBAction) switchValueChanged:(id)sender;
- (IBAction) indexValueChanged:(id)sender;

@end
