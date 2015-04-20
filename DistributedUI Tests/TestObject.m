//
//  TestObject.m
//  DistributedUI
//
//  Created by Caleb Cannon on 12/23/13.
//  Copyright (c) 2013 Caleb Cannon. All rights reserved.
//

#import "TestObject.h"

#import <objc/runtime.h>

@implementation TestObject

// To macro-ify
//   -- replace AccessorMethodName with ##accessorMethodName
//   --
static TestObject *accessorMethodNameNNInstance = nil;

+ (instancetype)accessorMethodName
{
	if (![[DUIManager sharedDUIManager] isHost])
	{
		DUIObjectIdentifier *identifier = [DUISingletonIdentifier identifierForSingletonWithClass:[self class]];
		return [[DUIManager sharedDUIManager] objectWithIdentifier:identifier];
	}
	@synchronized(self)
	{
		if (accessorMethodNameNNInstance == nil)
		{
			accessorMethodNameNNInstance = [super allocWithZone:NULL];
			accessorMethodNameNNInstance = [accessorMethodNameNNInstance init];
			method_exchangeImplementations(class_getClassMethod([accessorMethodNameNNInstance class], @selector(accessorMethodName)),
										   class_getClassMethod([accessorMethodNameNNInstance class], @selector(cwl_lockless_NNaccessorMethodName)));
			method_exchangeImplementations(class_getInstanceMethod([accessorMethodNameNNInstance class], @selector(init)),
										   class_getInstanceMethod([accessorMethodNameNNInstance class], @selector(cwl_onlyInitOnce)));
		}
	}
	
	return accessorMethodNameNNInstance;
}

+ (instancetype)cwl_lockless_NNaccessorMethodName
{
	return accessorMethodNameNNInstance;
}

+ (id)allocWithZone:(NSZone *)zone
{
	return [self accessorMethodName];
}

- (id)copyWithZone:(NSZone *)zone
{
	return self;
}

- (id)cwl_onlyInitOnce
{
	return self;
}


- (void) doSomeStuffWithAString:(NSString *)aString
{
    NSLog(@"doSomeStuffWithAString: %@", aString);
}

- (void) doSomeStuffWithAFloat:(float)aFloat
{
    NSLog(@"doSomeStuffWithAFloat: %f", aFloat);
}

- (void) doSomeStuffWithAnInt:(int)anInt;
{
    NSLog(@"doSomeStuffWithAFloat: %d", anInt);
}

- (void) doSomeStuffWithABool:(BOOL)aBool;
{
    NSLog(@"doSomeStuffWithAFloat: %c", aBool);
}

- (void) doSomeStuffWithAChar:(char)aChar;
{
    NSLog(@"doSomeStuffWithAFloat: %c", aChar);
}

- (void) doSomeStuffWithAString:(NSString *)aString
                          anInt:(int)anInt
                         aFloat:(float)aFloat
                          aBool:(BOOL)aBool
                          aChar:(char)aChar;
{
    NSLog(@"doSomeStuffWithAString: %@ anInt: %i aFloat: %f aBool: %i aChar: %c", aString, anInt, aFloat, aBool, aChar);
}

- (void) doSomeStuff
{
	NSLog(@"doSomeStuff: aString: %@ anInt: %i aFloat: %f aBool: %i aChar: %c", [self getAString], [self getAnInt], [self getAFloat], [self getABool], [self getAChar]);
}

- (NSString *) getAString
{
	return [NSString stringWithFormat:@"A String <%@>", [NSDate date]];
}

- (float) getAFloat
{
	return [NSDate timeIntervalSinceReferenceDate];
}

- (int) getAnInt;
{
	return [NSDate timeIntervalSinceReferenceDate];
}

- (BOOL) getABool;
{
	return (int)[NSDate timeIntervalSinceReferenceDate]%2;
}

- (char) getAChar;
{
	return 'a' + (short)[NSDate timeIntervalSinceReferenceDate]%('z' - 'a');
}

- (int) multiplyByTwo:(int)input
{
	return input*2;
}

- (char) theLetterC
{
	return 'C';
}

- (char) theLetterG
{
	return 'G';
}
- (float) pi
{
	return M_PI;
}

- (int) theMeaningOfLife
{
	return 42;
}

- (NSString *) theAuthorsFirstName
{
	return @"Caleb";
}

- (instancetype) init
{
	self = [super init];
	NSLog(@"Test object init: %@", self);
	return self;
}

- (void)dealloc
{
	NSLog(@"Test object dealloced: %@", self);
}

@end
