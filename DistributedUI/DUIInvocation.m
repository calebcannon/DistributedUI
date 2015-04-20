//
//  DUIInvocation.m
//  DistributedUI
//
//  Created by Caleb Cannon on 12/17/13.
//  Copyright (c) 2013 Caleb Cannon. All rights reserved.
//

#import "DUIInvocation.h"
#import "DistributedUI.h"

/*
 The initWithCoder function has some issues under ARC. Specifically, when unarchiving an object and assiging it the the
 invocation using [NSInvocation setArgument:...] the argument is over released when the invocation is released. Using
 [NSInvocation retainArguments] does not help
*/
#if __has_feature(objc_arc)
#error This file must be compiled with ARC disabled
#endif

// Keys used for encoding and decoding the invocation data
NSString * const kDUIInvocationClassName = @"DUIInvocationClassName";
NSString * const kDUIInvocationSelectorName = @"DUIInvocationSelectorName";
NSString * const kDUIInvocationIdentifier = @"DUIInvocationIdentifier";
NSString * const kDUIInvocationObjectIdentifier = @"DUIInvocationObjectIdentifier";
NSString * const kDUIInvocationNumberOfArguments = @"DUIInvocationNumberOfArguments";
NSString * const kDUIInvocationArguments = @"DUIInvocationArguments";

@implementation DUIInvocation

- (instancetype) initWithInvocation:(NSInvocation *)invocation identifier:(DUIObjectIdentifier *)identifer responseSempahore:(dispatch_semaphore_t)response_semaphore;
{
	self = [super init];
	if (self)
	{
		_objectIdentifier = [identifer retain];
		_invocation = [invocation retain];
		_identifier = [[DUIIdentifier identifier] retain];
		_response_semaphore = response_semaphore;
		
		NSAssert(identifer != nil, @"Distributed invocations must have an object identifier");
		NSAssert(invocation != nil, @"Distributed invocations must have an associated NSInvocation");
		NSAssert(_identifier != nil, @"Could not create identifier");
	}
	
	NSLog(@"Initialized Invocation: %@", self);
	
	return self;
}

- (void)dealloc
{
	//	NSLog(@"Freeing Invocation: %@", self);
	
    [_objectIdentifier release], _objectIdentifier = nil;
    [_invocation release], _invocation = nil;
	[_identifier release], _identifier = nil;
    
    [super dealloc];
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	if (self)
	{
		// Unpack the data
		NSString *className = [aDecoder decodeObjectForKey:kDUIInvocationClassName];
		NSString *selectorName = [aDecoder decodeObjectForKey:kDUIInvocationSelectorName];
		NSInteger numberOfArguments = [aDecoder decodeIntegerForKey:kDUIInvocationNumberOfArguments];
		NSArray *arguments = [aDecoder decodeObjectForKey:kDUIInvocationArguments];
		DUIObjectIdentifier *objectIdentifier = [aDecoder decodeObjectForKey:kDUIInvocationObjectIdentifier];
		DUIIdentifier *identifier = [aDecoder decodeObjectForKey:kDUIInvocationIdentifier];
		
        if (!className || !identifier || !objectIdentifier || !selectorName)
        {
            [NSException raise:@"DUIInvocationException" format:@"Invalid format"];
        }
        
		// Get a method signature from the target class
		Class class = NSClassFromString(className);
		SEL selector = NSSelectorFromString(selectorName);
		NSMethodSignature *methodSignature = [class instanceMethodSignatureForSelector:selector];

		// Create the new invocation
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
		[invocation setSelector:selector];
		[invocation retainArguments];
		
        // Add the arguments to the invocation
		for (NSInteger argumentIndex = 0; argumentIndex < arguments.count && argumentIndex < numberOfArguments+2; argumentIndex++)
		{
			NSDictionary *argumentDict = [arguments objectAtIndex:argumentIndex];
			
			NSString *argumentTypeStorage = [argumentDict objectForKey:@"type"];
			id argumentData = [argumentDict objectForKey:@"data"];
			
			if ([argumentTypeStorage isEqualToString:@"@"]) // @encode(id) == @
			{
				// This argument is an object archived as NSData. Unpack it and set the invocation arg.
                // Under arc the object is weakly referenced so we need to retain it
                id argumentObject = [NSKeyedUnarchiver unarchiveObjectWithData:argumentData];
				id __unsafe_unretained argumentObjectUnretained = argumentObject;
				[invocation setArgument:&argumentObjectUnretained atIndex:argumentIndex+2];
			}
			else if ([argumentTypeStorage isEqualToString:@"proxy"])
			{
				// This is a proxy for a remote object. The data is the identifier of the remote object so we create a new
				// remote object proxy and store that as the invocation argument
                DUIObjectIdentifier *remoteObjectIdentifier = [NSKeyedUnarchiver unarchiveObjectWithData:argumentData];
				DUIRemoteObjectProxy *proxy = [[DUIManager sharedDUIManager] remoteObjectProxyForIdentifier:remoteObjectIdentifier];
				[invocation setArgument:proxy atIndex:argumentIndex+2];
			}
			else
			{
				NSValue *value = argumentData;
				void *bytes;// = malloc(8);
				[value getValue:&bytes];
				[invocation setArgument:&bytes atIndex:argumentIndex+2];
//                free(bytes);
			}
		}
        
		_objectIdentifier = [objectIdentifier retain];
		_identifier = [identifier retain];
		_invocation = [invocation retain];
	}
	
	NSLog(@"decoded Invocation: %@", self);
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	NSMethodSignature *methodSignature = self.invocation.methodSignature;

	DUIObjectIdentifier *objectIdentifier = self.objectIdentifier;
	DUIIdentifier *identifier = self.identifier;

	NSString *className;
	if ([self.invocation.target isKindOfClass:[DUIRemoteObjectProxy class]])
		className = NSStringFromClass([(DUIRemoteObjectProxy *)self.invocation.target targetClass]);
	else
		className = NSStringFromClass([(NSObject *)self.invocation.target class]);
	
	NSString *selectorName = NSStringFromSelector(self.invocation.selector);
	NSUInteger numberOfArguments =  self.invocation.methodSignature.numberOfArguments;
	NSMutableArray *arguments = [NSMutableArray arrayWithCapacity:numberOfArguments];

	for (NSInteger argumentIndex = 2; argumentIndex < numberOfArguments; argumentIndex++)
	{
		id argumentData = nil;
		const char *argumentType = [methodSignature getArgumentTypeAtIndex:argumentIndex];
		NSString *argumentTypeStorage = [NSString stringWithUTF8String:argumentType];

		// Note: getArgument:atIndex copies the argument data into the argumentBuffer. The buffer
        // 'must be large enough to contain the data' .. we are however dealing with basic types,
        // int, float, id, etc, so this buffer should be suffifient

		// If the argument is an object that conforms to NSCoding, convert to an NSData object for transmission
		// Otherwise we get an NSValue object based on the data type
		if (strcmp (argumentType, @encode (id)) == 0)
		{
			id argumentObject;
			[self.invocation getArgument:&argumentObject atIndex:argumentIndex];

			if ([argumentObject conformsToProtocol:@protocol(NSCoding)])
			{
				argumentData = [NSKeyedArchiver archivedDataWithRootObject:argumentObject];
			}
			else
			{
				// If argumentObject is nil we don't add an identifier.  We may want to add a DUINilObject identified to make it explicetly nil when decoding.
				if (argumentObject)
				{
					DUIObjectIdentifier *identifier = [[DUIManager sharedDUIManager] addDistributedObject:argumentObject retain:NO];
					argumentData = identifier; // TODO: We can't pass this data so we can pass the identifier instead. A proxy will be constucted for the object on the remote end
					argumentTypeStorage = @"proxy";
				}
			}
		}
		else
		{
			void *argumentBuffer = malloc(8);
			memset(argumentBuffer, 0, 8);
			[self.invocation getArgument:&argumentBuffer atIndex:argumentIndex];
			argumentData = [NSValue valueWithBytes:&argumentBuffer objCType:argumentType];
		}
		
		if (argumentData)
		{
			NSDictionary *argumentDict = @{ @"type": argumentTypeStorage,
											@"data": argumentData };
			[arguments addObject:argumentDict];
		}
	}
    
    if (!className || !self.objectIdentifier || !selectorName)
    {
        [NSException raise:@"DUIInvocationException" format:@"Invalid format"];
    }

	[aCoder encodeObject:className forKey:kDUIInvocationClassName];
	[aCoder encodeObject:selectorName forKey:kDUIInvocationSelectorName];
	[aCoder encodeObject:objectIdentifier forKey:kDUIInvocationObjectIdentifier];
	[aCoder encodeInteger:numberOfArguments forKey:kDUIInvocationNumberOfArguments];
	[aCoder encodeObject:arguments forKey:kDUIInvocationArguments];
	[aCoder encodeObject:identifier forKey:kDUIInvocationIdentifier];
}

- (instancetype) copyWithZone:(NSZone *)zone
{
	id copy = [[[self class] allocWithZone:zone] initWithInvocation:self.invocation identifier:self.objectIdentifier responseSempahore:nil];
	
	return copy;
}

/*
- (BOOL)isEqual:(DUIInvocation *)object
{
	if ([object isKindOfClass:[self class]] &&
		[self.objectIdentifier isEqualToIdentifier:object.objectIdentifier] &&
		[NSStringFromSelector(self.invocation.selector) isEqual:NSStringFromSelector(object.invocation.selector)])
		return YES;
	else
		return NO;
}

- (NSUInteger)hash
{
	// Mike Ash's bit rotate macros for hashing
	#define INV_NSUINT_BIT (CHAR_BIT * sizeof(NSUInteger))
	#define INV_NSUINTROTATE(val, howmuch) ((((NSUInteger)val) << howmuch) | (((NSUInteger)val) >> (INV_NSUINT_BIT - howmuch)))
	return INV_NSUINTROTATE([self.identifier hash], 17) ^ INV_NSUINTROTATE([self.objectIdentifier hash], 18);
}
*/

- (NSString *)description
{
	NSMutableString *description = [NSMutableString stringWithFormat:@"%@", super.description];
	
	id target = self.invocation.target;
    
	NSString *className = NSStringFromClass([target class]);
	NSString *selectorName = NSStringFromSelector(self.invocation.selector);
	NSUInteger numberOfArguments =  self.invocation.methodSignature.numberOfArguments;
	NSMethodSignature *methodSignature = self.invocation.methodSignature;

    // Print the general description
    if (className == nil)
        [description appendFormat:@" { \n\tIdentifier=%@\n\tTarget=<No Target Set>\n\tSelector Name=%@", self.identifier, selectorName];
    else
        [description appendFormat:@" { \n\tIdentifier=%@\n\tTarget=%@\n\tClass Name=%@\n\tSelector Name=%@", self.identifier, [target description], className, selectorName];
    
    // Print the arguments
    [description appendFormat:@" { \n\tArguments=("];
	for (NSInteger argumentIndex = 2; argumentIndex < numberOfArguments; argumentIndex++)
	{
		id argumentData = nil;
		const char *argumentType = [methodSignature getArgumentTypeAtIndex:argumentIndex];
		NSString *argumentTypeStorage = [NSString stringWithUTF8String:argumentType];
		
		// Note: getArgument:atIndex copies the argument data into the argumentBuffer. The buffer
        // 'must be large enough to contain the data' .. we are however dealing with basic types,
        // int, float, id, etc, so this buffer should be suffifient
		// If the argument is an object that conforms to NSCoding, convert to an NSData object for transmission
		// Otherwise we get an NSValue object based on the data type
		if (strcmp (argumentType, @encode (id)) == 0)
		{
			id argumentObject;
			[self.invocation getArgument:&argumentObject atIndex:argumentIndex];
			
			if ([argumentObject conformsToProtocol:@protocol(NSCoding)])
				argumentData = argumentObject;
			else
				argumentData = @"<invalid>";

            [description appendFormat:@"\n\t\t %li: type=%@, data=%@;", (long)argumentIndex, argumentTypeStorage, argumentData];
        }
		else
		{
			void *argumentBuffer;// = malloc(8);
			[self.invocation getArgument:&argumentBuffer atIndex:argumentIndex];

            if (strcmp(argumentType, @encode(float)) == 0)
                [description appendFormat:@"\n\t\t %li: type=%@, data=%f;", (long)argumentIndex, argumentTypeStorage, *(float *)&argumentBuffer];
    
            else if (strcmp(argumentType, @encode (int)) == 0)
                [description appendFormat:@"\n\t\t %li: type=%@, data=%i;", (long)argumentIndex, argumentTypeStorage, *(int *)&argumentBuffer];
            
            else if (strcmp(argumentType, @encode (char)) == 0)
                [description appendFormat:@"\n\t\t %li: type=%@, data=%c;", (long)argumentIndex, argumentTypeStorage, *(char *)&argumentBuffer];
            
            else if (strcmp(argumentType, @encode(NSInteger)) == 0)
                [description appendFormat:@"\n\t\t %li: type=%@, data=%li;", (long)argumentIndex, argumentTypeStorage, *(long *)&argumentBuffer];

            else if (strcmp(argumentType, @encode(NSUInteger)) == 0)
                [description appendFormat:@"\n\t\t %li: type=%@, data=%lu;", (long)argumentIndex, argumentTypeStorage, *(unsigned long *)&argumentBuffer];

            else {
                argumentData = [NSValue valueWithBytes:&argumentBuffer objCType:argumentType];
                [description appendFormat:@"\n\t\t %li: type=%@, data=%@;", (long)argumentIndex, argumentTypeStorage, argumentData];
            }
        }
	}
	[description appendFormat:@"\n\t)"];

	if (self.invocation)
		[description appendFormat:@"\n\t Invocation=%@;", self.invocation.debugDescription];

	[description appendFormat:@"\n}"];
	return description;
}

@end
