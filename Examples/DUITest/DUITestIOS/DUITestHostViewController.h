//
//  DUITestHostViewController.h
//  
//
//  Created by Caleb Cannon on 3/17/14.
//
//

#import <UIKit/UIKit.h>

#include "DUITestSingletonClass.h"

@interface DUITestHostViewController : UIViewController

@property (strong) IBOutlet DUITestSingletonClass *testObject;

@property (strong) IBOutlet UILabel *textLabel;
@property (strong) IBOutlet UIImageView *imageView;
@property (strong) IBOutlet UIProgressView *progressView;
@property (strong) IBOutlet UIPageControl *pageControl;
@property (strong) IBOutlet UIActivityIndicatorView *activityIndicator;

@end
