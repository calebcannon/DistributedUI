//
//  DUISingleton.h
//  DistributedUI
//
//  Created by Caleb Cannon on 3/14/14.
//  Copyright (c) 2014 Caleb Cannon. All rights reserved.
//

@import Foundation;
#import <objc/runtime.h>

// TODO: When changing from host to proxy shared singletons need to be reset

//			method_exchangeImplementations(class_getClassMethod([accessorMethodName##Instance class], @selector(accessorMethodName)),
//										   class_getClassMethod([accessorMethodName##Instance class], @selector(cwl_lockless_##accessorMethodName)));
//			method_exchangeImplementations(class_getInstanceMethod([accessorMethodName##Instance class], @selector(init)),
//										   class_getInstanceMethod([accessorMethodName##Instance class], @selector(cwl_onlyInitOnce)));


#define DECLARE_SHARED_SINGLETON(classname, accessorMethodName) \
+ (instancetype) accessorMethodName;

#define SYNTHESIZE_SHARED_SINGLETON(classname, accessorMethodName) \
static __weak classname *accessorMethodName##Instance = nil; \
 \
+ (instancetype)accessorMethodName \
{ \
	if (![[DUIManager sharedDUIManager] isHost]) \
	{ \
		DUIObjectIdentifier *identifier = [DUISingletonIdentifier identifierForSingletonWithClass:[self class]]; \
		id shared_instance = [[DUIManager sharedDUIManager] remoteObjectProxyForIdentifier:identifier]; \
		return shared_instance; \
	} \
	@synchronized(self) \
	{ \
		if (accessorMethodName##Instance == nil) \
		{ \
			DUIObjectIdentifier *identifier = [DUISingletonIdentifier identifierForSingletonWithClass:[self class]]; \
			id instance = [[super allocWithZone:NULL] init]; \
			accessorMethodName##Instance = instance; \
			[[DUIManager sharedDUIManager] addDistributedObject:accessorMethodName##Instance withIdentifier:identifier retain:YES]; \
			instance = nil; \
		} \
	} \
	 \
	return accessorMethodName##Instance; \
} \
 \
+ (instancetype)cwl_lockless_##accessorMethodName \
{ \
	return accessorMethodName##Instance; \
} \
 \
+ (id)allocWithZone:(NSZone *)zone \
{ \
	return [self accessorMethodName]; \
} \
 \
- (id)copyWithZone:(NSZone *)zone \
{ \
	return self; \
} \
 \
- (id)cwl_onlyInitOnce \
{ \
	return self; \
} \

