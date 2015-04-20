//
//  NSString+MD5.m
//  DistributedUI
//
//  Created by Caleb Cannon on 3/14/14.
//  Copyright (c) 2014 Caleb Cannon. All rights reserved.
//

#import "NSString+MD5.h"

#import <CommonCrypto/CommonDigest.h>

@implementation NSString (MD5)

- (NSString *) md5
{
	const char *cStr = [self UTF8String];
	unsigned char digest[16];

	CC_MD5( cStr, (int)strlen(cStr), digest ); // This is the md5 call
	
	NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
	
	for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
		[output appendFormat:@"%02x", digest[i]];
	
	return  output;
	
}

@end
