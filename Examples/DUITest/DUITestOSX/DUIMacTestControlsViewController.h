//
//  DUIMacTestControlsViewController.h
//  DUITest
//
//  Created by Caleb Cannon on 4/18/15.
//  Copyright (c) 2015 Caleb Cannon. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DUIMacTestControlsViewController : NSViewController

@property (weak) IBOutlet NSButton *startHostButton;
@property (weak) IBOutlet NSTextField *hostStatusLabel;
@property (weak) IBOutlet NSButton *testHostButton;
@property (weak) IBOutlet NSButton *stopHostButton;

@property (weak) IBOutlet NSButton *startClientButton;
@property (weak) IBOutlet NSTextField *clientStatusLabel;
@property (weak) IBOutlet NSButton *browseButton;
@property (weak) IBOutlet NSButton *testClientButton;
@property (weak) IBOutlet NSButton *stopClientButton;

- (IBAction)startHost:(id)sender;
- (IBAction)startClient:(id)sender;
- (IBAction)browse:(id)sender;
- (IBAction)stop:(id)sender;

@end
