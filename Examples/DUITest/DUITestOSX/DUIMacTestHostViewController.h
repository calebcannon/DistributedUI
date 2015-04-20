//
//  DUIMacTestHostViewController.h
//  DUITest
//
//  Created by Caleb Cannon on 4/18/15.
//  Copyright (c) 2015 Caleb Cannon. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DUIMacTestHostViewController : NSViewController

@property (strong) IBOutlet DUITestSingletonClass *testObject;

@property (strong) IBOutlet NSTextField *textLabel;
@property (strong) IBOutlet NSImageView *imageView;
@property (strong) IBOutlet NSProgressIndicator *progressView;
@property (strong) IBOutlet NSMatrix *pageControl;
@property (strong) IBOutlet NSProgressIndicator *activityIndicator;

@end
