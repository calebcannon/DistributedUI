//
//  DistributedUI.m
//  DistributedUI
//
//  Created by Caleb Cannon on 4/8/15.
//  Copyright (c) 2015 Caleb Cannon. All rights reserved.
//


NSString * const DUIException = @"DUIException";

// Default log levels
static NSUInteger DUILogFlagsSet = DUILogError |
								   DUILogWarning |
								   DUILogInfo | DUILogVerbose;

void DUISetLogFlags(NSUInteger flags)
{
	DUILogFlagsSet = flags;
}

void DUILog(NSUInteger flags, NSString *format, ...)
{
	if (flags & DUILogFlagsSet)
	{
		va_list args;
		va_start(args, format);
		NSLogv(format, args);
		va_end(args);
	}
}


