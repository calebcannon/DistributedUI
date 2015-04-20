//
//  DUITestClientViewController.h
//  
//
//  Created by Caleb Cannon on 3/17/14.
//
//

#import <UIKit/UIKit.h>

#import "DUITestSingletonClass.h"

@interface DUITestClientViewController : UIViewController

@property (strong) IBOutlet DUITestSingletonClass *testObject;

@property (strong) IBOutlet UITextField *textField;
@property (strong) IBOutlet UIImageView *imageView;
@property (strong) IBOutlet UISlider *slider;
@property (strong) IBOutlet UISwitch *toggleSwitch;
@property (strong) IBOutlet UISegmentedControl *segmentedControl;

- (IBAction) textDidChange;
- (IBAction) selectImage;
- (IBAction) floatValueChanged;
- (IBAction) switchValueChanged;
- (IBAction) indexValueChanged;

@end
