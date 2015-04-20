//
//  DUINotificationObserver.m
//  DistributedUI
//
//  Created by Caleb Cannon on 3/20/14.
//  Copyright (c) 2014 Caleb Cannon. All rights reserved.
//

#import "DUINotificationObservationInfo.h"

@implementation DUINotificationObservationInfo

- (instancetype) initWithName:(NSString *)name objectIdentifier:(DUIObjectIdentifier *)objectIdentifier observerIdentifier:(DUIObjectIdentifier *)observerIdentifier selector:(SEL)selector
{
	self = [super init];
	if (self)
	{
		_name = name;
		_objectIdentifier = objectIdentifier;
		_observerIdentifier = observerIdentifier;
		_selector = selector;
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	if (self)
	{
		_name = [aDecoder decodeObjectForKey:@"notificationName"];
		_objectIdentifier = [aDecoder decodeObjectForKey:@"objectIdentifier"];
		_observerIdentifier = [aDecoder decodeObjectForKey:@"observerIdentifier"];
		_selector = NSSelectorFromString([aDecoder decodeObjectForKey:@"selector"]);
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:self.name forKey:@"notificationName"];
	[aCoder encodeObject:self.objectIdentifier forKey:@"objectIdentifier"];
	[aCoder encodeObject:self.observerIdentifier forKey:@"observerIdentifier"];
	[aCoder encodeObject:NSStringFromSelector(self.selector) forKey:@"selector"];
}

- (BOOL)isEqual:(DUINotificationObservationInfo *)info
{
	if (self == info)
		return YES;
	
	if (![info isKindOfClass:[DUINotificationObservationInfo class]])
		return NO;

	if (![self.name isEqualToString:info.name])
		return NO;
	
	if (![self.objectIdentifier isEqualToIdentifier:info.objectIdentifier])
		return NO;
	
	return YES;
}

- (NSUInteger)hash
{
	return self.name.hash + self.objectIdentifier.hash;
}

- (id)copyWithZone:(NSZone *)zone
{
	id copy = [[[self class] allocWithZone:zone] initWithName:self.name objectIdentifier:self.objectIdentifier observerIdentifier:self.observerIdentifier selector:self.selector];
	
	return copy;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@: %p; name = %@; object identifier = %@; observer identifier = %@; selector = %@>", [self class], self, self.name, self.objectIdentifier, self.observerIdentifier, NSStringFromSelector(self.selector)];
}

@end
