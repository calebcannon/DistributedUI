//
//  DUIDrawToolsViewController.h
//  DUIDraw
//
//  Created by Caleb Cannon on 3/28/14.
//  Copyright (c) 2014 Caleb Cannon. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DUIColorPickerView;

@interface DUIDrawToolsViewController : UIViewController

- (IBAction) changeColor:(DUIColorPickerView *)sender;
- (IBAction) changeBrushSize:(UISlider *)sender;

@end
