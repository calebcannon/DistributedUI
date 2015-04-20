//
//  DUITestSingletonClass.m
//  DUITest
//
//  Created by Caleb Cannon on 3/17/14.
//  Copyright (c) 2014 Caleb Cannon. All rights reserved.
//

#import "DUITestSingletonClass.h"

@import DistributedUI;

NSString * const DUITestFloatValueChangedNotification = @"DUITestFloatValueChangedNotification";
NSString * const DUITestTextValueChangedNotification = @"DUITestTextValueChangedNotification";
NSString * const DUITestSwitchValueChangedNotification = @"DUITestSwitchValueChangedNotification";
NSString * const DUITestImageValueChangedNotification = @"DUITestImageValueChangedNotification";
NSString * const DUITestIndexValueChangedNotification = @"DUITestIndexValueChangedNotification";

@implementation DUITestSingletonClass

@synthesize floatValue = _floatValue;
@synthesize textValue = _textValue;
@synthesize switchValue = _switchValue;
@synthesize imageValue = _imageValue;
@synthesize indexValue = _indexValue;

//DECLARE_SHARED_SINGLETON(DUITestSingletonClass, sharedInstance) \
//static DUITestSingletonClass *classname##SharedInstance = nil;

static DUITestSingletonClass *DUISingletonClassSharedInstance = nil;

SYNTHESIZE_SHARED_SINGLETON(DUITestSingletonClass, sharedInstance)

- (void)setFloatValue:(float)floatValue
{
	_floatValue = floatValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:DUITestFloatValueChangedNotification object:self userInfo:nil];
}

- (float)floatValue
{
	return _floatValue;
}

-(void)setTextValue:(NSString *)textValue
{
	_textValue = [textValue copy];
	[[NSNotificationCenter defaultCenter] postNotificationName:DUITestTextValueChangedNotification object:self userInfo:nil];
}

-(NSString *)textValue
{
	return _textValue;
}

- (void)setSwitchValue:(BOOL)switchValue
{
	_switchValue = switchValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:DUITestSwitchValueChangedNotification object:self userInfo:nil];
}

-(BOOL)switchValue
{
	return _switchValue;
}

- (void)setImageValue:(IMAGE_CLASS *)imageValue
{
	_imageValue = imageValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:DUITestImageValueChangedNotification object:self userInfo:nil];
}

- (IMAGE_CLASS *)imageValue
{
	return _imageValue;
}

- (void)setIndexValue:(unsigned int)indexValue
{
	_indexValue = indexValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:DUITestIndexValueChangedNotification object:self userInfo:nil];
}

- (unsigned int)indexValue
{
	return _indexValue;
}

@end
