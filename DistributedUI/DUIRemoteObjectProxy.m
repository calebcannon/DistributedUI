//
//  DUObjectProxy.m
//  DistributedUI
//
//  Created by Caleb Cannon on 12/6/13.
//  Copyright (c) 2013 Caleb Cannon. All rights reserved.
//

#import "DUIRemoteObjectProxy.h"
#import "DistributedUI.h"



@interface DUIRemoteObjectProxy ()

@property (retain) DUIPeer *peer;

@end



@implementation DUIRemoteObjectProxy

@synthesize identifier = _identifier;
@synthesize isValid = _isValid;
@synthesize peer = _peer;

- (instancetype) initWithIdentifier:(DUIObjectIdentifier *)identifier peer:(DUIPeer *)peer
{
	if (self)
	{
		NSAssert(peer != nil, @"Can not create remote proxy without a peer");
		
		_identifier = identifier;
		_peer = peer;
		_targetClass = NSClassFromString(identifier.representedClassName);
	}
	return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    return [self.targetClass instanceMethodSignatureForSelector:aSelector];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return YES;
}

- (BOOL)isKindOfClass:(Class)aClass
{
	return (aClass == [self class]);
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
	NSAssert(_peer != nil, @"Could not forward invocation: No peer");
	NSAssert(invocation != nil, @"Could not forward invocation: Nothing to invoke");
	
	DUILog(DUILogDebug, @"Forwarding invocation: %@", invocation);
	[self.peer forwardInvocation:invocation forProxy:self];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@: %p; identifier = %@; valid = %@; class = %@; peer = %@>", [self class], self, self.identifier, self.isValid ? @"YES" : @"NO", self.targetClass, self.peer];
}

- (NSString *)descriptionWithLocale:(NSLocale *)locale
{
	return [NSString stringWithFormat:@"<%@: %p; identifier = %@; valid = %@; class = %@; peer = %@>", [self class], self, self.identifier, self.isValid ? @"YES" : @"NO", self.targetClass, self.peer];
}

@end
