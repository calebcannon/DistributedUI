//
//  DUIColorPickerView.m
//  DUIDraw
//
//  Created by Caleb Cannon on 4/17/15.
//  Copyright (c) 2015 Caleb Cannon. All rights reserved.
//

#import "DUIColorPickerView.h"

@implementation DUIColorPickerView

- (void)drawRect:(CGRect)rect
{
	[[UIImage imageNamed:@"Colors"] drawInRect:self.bounds];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	CGPoint touchPoint = [touch locationInView:self];
	
	self.color = [UIColor colorWithHue:touchPoint.x / self.bounds.size.width saturation:1.0 brightness:touchPoint.y / self.bounds.size.height alpha:1.0];
	[self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	CGPoint touchPoint = [touch locationInView:self];
	
	self.color = [UIColor colorWithHue:touchPoint.x / self.bounds.size.width saturation:1.0 brightness:touchPoint.y / self.bounds.size.height alpha:1.0];	
	[self sendActionsForControlEvents:UIControlEventValueChanged];
}

@end
