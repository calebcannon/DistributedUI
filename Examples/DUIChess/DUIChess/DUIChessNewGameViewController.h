//
//  DUINewGameViewController.h
//  DUIChess
//
//  Created by Caleb Cannon on 3/19/14.
//  Copyright (c) 2014 Caleb Cannon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DUIChessNewGameViewController : UIViewController <MCBrowserViewControllerDelegate>

- (IBAction)host:(id)sender;
- (IBAction)connect:(id)sender;

@end
