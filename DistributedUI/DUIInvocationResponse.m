
//
//  DUIInvocationResponse.m
//  DistributedUI
//
//  Created by Caleb Cannon on 12/28/13.
//  Copyright (c) 2013 Caleb Cannon. All rights reserved.
//

#import "DUIInvocationResponse.h"
#import "DUIInvocation.h"
#import "DUIManager.h"

/*
 The setArgument: function has some issues under ARC. Specifically, the function does not know if the
 passed argument is an objective-c type or some random location in memory, thus the compiler can not
 manage the memory using ARC
*/
#if __has_feature(objc_arc)
#error This file must be compiled with ARC disabled
#endif


@implementation DUIInvocationResponse

+ (instancetype) invocationResponseWithIdentifier:(DUIIdentifier *)identifier responseData:(NSData *)responseData
{
	return [[[self alloc] initWithIdentifier:identifier responseData:responseData] autorelease];
}

- (instancetype) initWithIdentifier:(DUIIdentifier *)identifier responseData:(NSData *)data
{
	self = [super init];
	if (self)
	{
		_invocationIdentifier = [identifier retain];
		_responseData = [data retain];
	}
	
	NSLog(@"Created invocation response: %@", self);
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	if (self)
	{
		_responseData = [[aDecoder decodeObjectForKey:@"data"] retain];
		_invocationIdentifier = [[aDecoder decodeObjectForKey:@"invocationIdentifier"] retain];
	}

	NSLog(@"Decoded invocation response: %@", self);
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:self.responseData forKey:@"data"];
	[aCoder encodeObject:self.invocationIdentifier forKey:@"invocationIdentifier"];
}

- (void)dealloc
{
	[_responseData release], _responseData = nil;
	[_invocationIdentifier release], _invocationIdentifier = nil;

	[super dealloc];
}

+ (instancetype) invocationResponseWithInvocation:(DUIInvocation *)invocation
{
	NSMethodSignature *methodSignature = invocation.invocation.methodSignature;
	NSUInteger methodReturnLength = methodSignature.methodReturnLength;

	// For methods without a return value the return length is 0
	if (methodReturnLength == 0)
	{
		DUIInvocationResponse *response = [DUIInvocationResponse invocationResponseWithIdentifier:invocation.identifier responseData:nil];
		return response;
	}

	// Get the return value and return a DUIInvocationResponse
	// TODO: Create proxies for return objects based on policy
	const char *methodReturnType = methodSignature.methodReturnType;
	NSData *resultData = nil;
	if (strcmp(methodReturnType, @encode(id)) == 0)
	{
		id resultObject;
		[invocation.invocation getReturnValue:&resultObject];
		if ([resultObject conformsToProtocol:@protocol(NSCoding) ])
			resultData = [NSKeyedArchiver archivedDataWithRootObject:resultObject];
		else
		{
			DUIObjectIdentifier *identifer = [DUIObjectIdentifier identifierForObject:resultObject representedClass:[resultObject class]];
			resultData = [NSKeyedArchiver archivedDataWithRootObject:identifer];
		}
	}
	else
	{
		void *returnValue = malloc(methodReturnLength);
		[invocation.invocation getReturnValue:returnValue];
		resultData = [NSData dataWithBytes:returnValue length:methodReturnLength];
		free(returnValue);
	}

	DUIInvocationResponse *response = [DUIInvocationResponse invocationResponseWithIdentifier:invocation.identifier responseData:resultData];
	return response;
}

- (void) setForInvocation:(DUIInvocation *)duiInvocation
{
	NSInvocation *invocation = duiInvocation.invocation;

	NSMethodSignature *methodSignature = invocation.methodSignature;
	NSUInteger methodReturnLength = methodSignature.methodReturnLength;
	
	// For methods without a return value the return length is 0
	if (methodReturnLength == 0)
		return;
	
	// Get the return value and return a DUIInvocationResponse
	// TODO: Create proxies for return objects based on policy
	const char *methodReturnType = methodSignature.methodReturnType;

	if (strcmp(methodReturnType, @encode(id)) == 0)
	{
		id resultObject = [NSKeyedUnarchiver unarchiveObjectWithData:self.responseData];
		DUILog(DUILogVerbose, @"setting response object: %@ for invocation %@", resultObject, duiInvocation);
		if ([resultObject isKindOfClass:[DUIIdentifier class]])
			resultObject = [[DUIManager sharedDUIManager] remoteObjectProxyForIdentifier:resultObject];
		[resultObject retain];
		[invocation setReturnValue:&resultObject];
	}
	else
	{
		const void *bytes[self.responseData.length];
		DUILog(DUILogVerbose, @"setting response bytes %@ for invocation %@", self.responseData, duiInvocation);
		[self.responseData getBytes:bytes length:self.responseData.length];
		[invocation setReturnValue:bytes];
	}
}

- (NSString *)description
{
	NSString *description = [NSString stringWithFormat:@"<%@: %p; identifier = %@; data = %@>", self.class, self, self.invocationIdentifier, self.responseData];
	return description;
}

@end
