//
//  DUINotification.m
//  DistributedUI
//
//  Created by Caleb Cannon on 3/20/14.
//  Copyright (c) 2014 Caleb Cannon. All rights reserved.
//

#import "DUINotification.h"
#import "DUIIdentifier.h"
#import "DUIManager.h"


@implementation DUINotification

@synthesize name = _name;
@synthesize objectIdentifier = _objectIdentifier;
@synthesize userInfo = _userInfo;
@synthesize object = _object;

+ (instancetype) notificationWithNotification:(NSNotification *)notification
{
	DUINotification *duiNotification = [[[self class] alloc] initWithName:notification.name
														 objectIdentifier:[[DUIManager sharedDUIManager] identifierForObject:notification.object]
																 userInfo:notification.userInfo];
	return duiNotification;
}

- (instancetype) initWithName:(NSString *)name objectIdentifier:(DUIObjectIdentifier *)objectIdentifier userInfo:(NSDictionary *)userInfo
{
	//self = [super initWithName:name object:nil userInfo:userInfo];
	if (self)
	{
		_name = [name copy];
		_objectIdentifier = objectIdentifier;
		_userInfo = userInfo;
		_identifier = [DUIIdentifier identifier];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	if (self)
	{
		_name = [aDecoder decodeObjectForKey:@"name"];
		_objectIdentifier = [aDecoder decodeObjectForKey:@"objectIdentifier"];
		_userInfo = [aDecoder decodeObjectForKey:@"userInfo"];
		_identifier = [aDecoder decodeObjectForKey:@"identifier"];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:self.name forKey:@"name"];
	[aCoder encodeObject:self.objectIdentifier forKey:@"objectIdentifier"];
	[aCoder encodeObject:self.userInfo forKey:@"userInfo"];
	[aCoder encodeObject:self.identifier forKey:@"identifier"];
}

- (id)copyWithZone:(NSZone *)zone
{
	id copy = [[[self class] allocWithZone:zone] initWithName:self.name objectIdentifier:self.objectIdentifier userInfo:self.userInfo];
	return copy;
}

- (NSNotification *) notification
{
	return [NSNotification notificationWithName:self.name object:self.object userInfo:self.userInfo];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@: %p; identifier = %@; name = %@; object identifier = %@; user info = %@>", [self class], self, self.identifier, self.name, self.objectIdentifier, self.userInfo];
}

@end
