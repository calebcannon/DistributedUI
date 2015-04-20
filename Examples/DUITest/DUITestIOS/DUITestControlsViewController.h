//
//  DFirstViewController.h
//  DUITest
//
//  Created by Caleb Cannon on 12/6/13.
//  Copyright (c) 2013 Caleb Cannon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DUITestControlsViewController : UIViewController

@property (weak) IBOutlet UIButton *startHostButton;
@property (weak) IBOutlet UILabel *hostStatusLabel;
@property (weak) IBOutlet UIButton *testHostButton;
@property (weak) IBOutlet UIButton *stopHostButton;

@property (weak) IBOutlet UIButton *startClientButton;
@property (weak) IBOutlet UILabel *clientStatusLabel;
@property (weak) IBOutlet UIButton *browseButton;
@property (weak) IBOutlet UIButton *testClientButton;
@property (weak) IBOutlet UIButton *stopClientButton;

- (IBAction)startHost:(id)sender;
- (IBAction)startClient:(id)sender;
- (IBAction)browse:(id)sender;
- (IBAction)stop:(id)sender;

@end
