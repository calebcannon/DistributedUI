// Internal logging mechanism. Log levels are enabled/disabled with DUIEnableLogLevel/DUIDisableLogLevel

//
//  DistributedUI.h
//  DistributedUI
//
//  Created by Caleb Cannon on 4/6/15.
//  Copyright (c) 2015 Caleb Cannon. All rights reserved.
//

@import Foundation;




//! Project version number for DistributedUI.
FOUNDATION_EXPORT double DistributedUIVersionNumber;

//! Project version string for DistributedUI.
FOUNDATION_EXPORT const unsigned char DistributedUIVersionString[];

/// Exception type for DUI related exceptions
extern NSString * const DUIException;




#import "DUIManager.h"
#import "DUIRemoteObjectProxy.h"
#import "DUIMethods.h"
#import "DUIPeer.h"
#import "DUIInvocation.h"
#import "DUIInvocationResponse.h"
#import "DUINotification.h"
#import "DUINotificationObservationInfo.h"
#import "DUIIdentifier.h"
#import "DUISingleton.h"




#if defined(__cplusplus)
#define DUI_EXTERN extern "C"
#else
#define DUI_EXTERN extern
#endif



/// Internal logging mechanism. Log levels are enabled/disabled with DUIEnableLogLevel/DUIDisableLogLevel

typedef NS_ENUM(NSUInteger, DUILogFlags)
{
	DUILogError				= 1 << 0,
	DUILogWarning			= 1 << 1,
	DUILogInfo				= 1 << 2,
	DUILogDebug				= 1 << 3,
	DUILogMultipeerSession	= 1 << 4,
	DUILogTrace				= 1 << 5,
	
	DUILogVerbose			= 0xffffffff
};

/// Internal log method
DUI_EXTERN void DUILog(NSUInteger flags, NSString *format, ...) NS_FORMAT_FUNCTION(2, 3);

/// Enable / disable log levels
DUI_EXTERN void DUISetLogFlags(NSUInteger flags);
