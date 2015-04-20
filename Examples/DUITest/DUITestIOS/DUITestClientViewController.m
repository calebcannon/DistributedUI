//
//  DUITestClientViewController.m
//  
//
//  Created by Caleb Cannon on 3/17/14.
//
//

#import "DUITestClientViewController.h"

@interface DUITestClientViewController () <UIImagePickerControllerDelegate, UITextFieldDelegate, UINavigationControllerDelegate>

@end



@implementation DUITestClientViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	
	self.testObject = [DUITestSingletonClass sharedInstance];
//	NSLog(@"Model: %@", self.testObject);
	
	return self;
}

- (void)viewWillAppear:(BOOL)animated
{
	self.textField.text = self.testObject.textValue;
	self.imageView.image = self.testObject.imageValue;
	self.slider.value = self.testObject.floatValue;
	self.segmentedControl.selectedSegmentIndex = self.testObject.indexValue;
	self.toggleSwitch.on = self.testObject.switchValue;
}

- (IBAction) textDidChange
{
	self.testObject.textValue = self.textField.text;
}

- (IBAction) floatValueChanged
{
	self.testObject.floatValue = self.slider.value;
}

- (IBAction) switchValueChanged
{
	self.testObject.switchValue = self.toggleSwitch.on;
}

- (IBAction) indexValueChanged
{
	self.testObject.indexValue = self.segmentedControl.selectedSegmentIndex;
}

- (IBAction) selectImage
{
	UIImagePickerController *picker = [[UIImagePickerController alloc] init];
	picker.delegate = self;
	[self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
	[self.testObject setImageValue:image];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[self.textField resignFirstResponder];
	return NO;
}

@end
