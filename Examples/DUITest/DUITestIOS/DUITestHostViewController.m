//
//  DUITestHostViewController.m
//  
//
//  Created by Caleb Cannon on 3/17/14.
//
//

#import "DUITestHostViewController.h"

@interface DUITestHostViewController ()

@end

@implementation DUITestHostViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	self.testObject = [DUITestSingletonClass sharedInstance];
	return self;
}

- (void)viewDidLoad
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textValueChanged:) name:DUITestTextValueChangedNotification object:self.testObject];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageValueChanged:) name:DUITestImageValueChangedNotification object:self.testObject];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(floatValueChanged:) name:DUITestFloatValueChangedNotification object:self.testObject];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(indexValueChanged:) name:DUITestIndexValueChangedNotification object:self.testObject];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(switchValueChanged:) name:DUITestSwitchValueChangedNotification object:self.testObject];
}

- (void) textValueChanged:(NSNotification *)notification
{
	self.textLabel.text = self.testObject.textValue;
}

- (void) imageValueChanged:(NSNotification *)notification
{
	self.imageView.image = self.testObject.imageValue;
}

- (void) floatValueChanged:(NSNotification *)notification
{
	self.progressView.progress = self.testObject.floatValue;
}

- (void) indexValueChanged:(NSNotification *)notification
{
	self.pageControl.currentPage = self.testObject.indexValue;
}

- (void) switchValueChanged:(NSNotification *)notification
{
	if (self.testObject.switchValue)
		[self.activityIndicator startAnimating];
	else
		[self.activityIndicator stopAnimating];
}

@end
