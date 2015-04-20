//
//  DUITestSingletonClass.h
//  DUITest
//
//  Created by Caleb Cannon on 3/17/14.
//  Copyright (c) 2014 Caleb Cannon. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 This singleton class is used to demonstrate the DUI singleton design pattern.  This class
 implements several properties that send notifications when changed
*/

#if TARGET_OS_IPHONE
#define IMAGE_CLASS UIImage
#else
#define IMAGE_CLASS NSImage
#endif

extern NSString * const DUITestFloatValueChangedNotification;
extern NSString * const DUITestTextValueChangedNotification;
extern NSString * const DUITestSwitchValueChangedNotification;
extern NSString * const DUITestImageValueChangedNotification;
extern NSString * const DUITestIndexValueChangedNotification;

@interface DUITestSingletonClass : NSObject

+ (instancetype) sharedInstance;

@property (assign) float floatValue;
@property (copy) NSString *textValue;
@property (assign) BOOL switchValue;
@property (copy) IMAGE_CLASS *imageValue;
@property (assign) unsigned int indexValue;

@end
