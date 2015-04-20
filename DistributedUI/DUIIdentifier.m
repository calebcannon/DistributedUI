//
//  DUIIdentifier.m
//  DistributedUI
//
//  Created by Caleb Cannon on 12/27/13.
//  Copyright (c) 2013 Caleb Cannon. All rights reserved.
//


#import "DUIIdentifier.h"
#import "DistributedUI.h"
#import "NSString+MD5.h"


// Generates UUID as an NSString. Used for creating proxy identifiers
NSString *GenerateUUIDString(void);
NSString *GenerateUUIDString()
{
	CFUUIDRef theUUID = CFUUIDCreate(NULL);
	CFStringRef string = CFUUIDCreateString(NULL, theUUID);
	CFRelease(theUUID);
	return (__bridge_transfer NSString *)string;
}


@interface DUIIdentifier ()

@property (copy) NSString *identifierName;

- (instancetype) initWithIdentifierName:(NSString *)identifierName;

@end



@interface DUIObjectIdentifier ()

@property (copy) NSString *representedClassName;

- (instancetype) initWithIdentifierName:(NSString *)identifierName representedClassName:(NSString *)className;

@end



@implementation DUIIdentifier

+ (instancetype) identifier
{
	NSString *identifierName = GenerateUUIDString();
	DUIIdentifier *identifier = [[DUIIdentifier alloc] initWithIdentifierName:identifierName];
	return identifier;
}

- (instancetype) initWithIdentifierName:(NSString *)identifierName;
{
	self = [super init];
	if (self)
	{
		_identifierName = [identifierName copy];
	}
	return self;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	if (self)
	{
		self.identifierName = [aDecoder decodeObjectForKey:@"identifierName"];
	}
	
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:self.identifierName forKey:@"identifierName"];
}

- (NSString *)description
{
	return self.identifierName.description;
}

- (BOOL)isEqual:(id)object
{
	if ([object isKindOfClass:[DUIIdentifier class]])
		return [self.identifierName isEqualToString:[(DUIIdentifier *)object identifierName]];
	else
		return NO;
}

- (BOOL)isEqualToIdentifier:(DUIObjectIdentifier *)identifier
{
	return [self.identifierName isEqualToString:identifier.identifierName];
}

- (NSUInteger)hash
{
	// Mike Ash's bit rotate macros for hashing
	#define NSUINT_BIT (CHAR_BIT * sizeof(NSUInteger))
	#define NSUINTROTATE(val, howmuch) ((((NSUInteger)val) << howmuch) | (((NSUInteger)val) >> (NSUINT_BIT - howmuch)))
	return NSUINTROTATE([self.identifierName hash], 17);
}

- (instancetype) copyWithZone:(NSZone *)zone
{
	id copy = [[[self class] allocWithZone:zone] initWithIdentifierName:self.identifierName];
	
	return copy;
}

@end



@implementation DUIObjectIdentifier

+ (instancetype) identifierForObject:(id)object representedClass:(Class)objectClass
{
	if (object == nil)
		return nil;
	
	if (objectClass == nil)
		objectClass = [object class];

	NSString *identifierName = [NSString stringWithFormat:@"%@_%@", [objectClass description], GenerateUUIDString()];
	NSString *representedClassName = NSStringFromClass([object class]);

	DUIObjectIdentifier *identifier = [[[self class] alloc] initWithIdentifierName:identifierName representedClassName:representedClassName];

	return identifier;
}

+ (instancetype) identifierForSingletonWithClass:(Class)objectClass
{
	if (objectClass == nil)
		[NSException raise:DUIException format:@"objectClass can not be nil"];
	
	NSString *identifierName = [NSString stringWithFormat:@"%@_%@", [objectClass description], [[objectClass description] md5]];
	
	DUIObjectIdentifier *identifier = [[[self class] alloc] initWithIdentifierName:identifierName representedClassName:nil];

	return identifier;
}

- (instancetype) initWithIdentifierName:(NSString *)identifierName representedClassName:(NSString *)className;
{
	self = [super initWithIdentifierName:identifierName];
	if (self)
	{
		_representedClassName = className;
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject:self.representedClassName forKey:@"representedClassName"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self)
	{
		_representedClassName = [aDecoder decodeObjectForKey:@"representedClassName"];
	}
	
	return self;
}

- (instancetype) copyWithZone:(NSZone *)zone
{
	id copy = [[[self class] allocWithZone:zone] initWithIdentifierName:self.identifierName representedClassName:self.representedClassName];
	
	return copy;
}

@end


@implementation DUISingletonIdentifier

+ (instancetype) identifierForSingletonWithClass:(Class)objectClass
{
	if (objectClass == nil)
		[NSException raise:@"Invalid Arguments" format:@"objectClass can not be nil"];
	
	NSString *identifierName = [NSString stringWithFormat:@"%@_%@", [objectClass description], [[objectClass description] md5]];
	
	DUISingletonIdentifier *identifier = [[[self class] alloc] initWithIdentifierName:identifierName representedClassName:NSStringFromClass(objectClass)];
	
	return identifier;
}

- (instancetype) initWithIdentifierName:(NSString *)identifierName class:(NSString *)className;
{
	self = [super initWithIdentifierName:identifierName representedClassName:className];

	return self;
}

@end