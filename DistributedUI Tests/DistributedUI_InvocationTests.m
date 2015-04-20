//
//  DistributedUI_InvocationTests.m
//  DistributedUI
//
//  Created by Caleb Cannon on 12/22/13.
//  Copyright (c) 2013 Caleb Cannon. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "TestObject.h"

@interface DistributedUI_InvocationTests : XCTestCase
{
	DUIManager *dui;
	DUIManager *duiRemote;
}

@end


@implementation DistributedUI_InvocationTests

- (void)setUp
{
    [super setUp];
	
	dui = [DUIManager new];
	dui.isHost = YES;
	
	duiRemote = [DUIManager new];
	duiRemote.isHost = NO;
	
	[dui startDistributedInterfaceSession];
	[duiRemote startDistributedInterfaceSession];
	
	XCTAssertNotificationReceived(DUIManagerFoundPeerNotification, duiRemote, 5.0, @"Service discovery failed");
	
	NSLog(@"Connecting to Available Services: %@", duiRemote.availableServices);
	for (DUINetService *service in duiRemote.availableServices)
	{
		[service connect];
		XCTAssertNotificationReceived(DUINetServiceDidConnect, service, 5.0, @"Service failed to connect", service);
	}
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void) testArchivedInvocations
{
	TestObject *testObj = [[TestObject alloc] init];
	DUIObjectIdentifier *identifier = [DUIObjectIdentifier identifierForObject:testObj representedClass:nil];
    DUIRemoteObjectProxy *proxy = [[DUIRemoteObjectProxy alloc] initWithIdentifier:identifier service:nil];

	[testObj doSomeStuff];
	
	SEL selector = @selector(doSomeStuffWithAFloat:);
	NSMethodSignature *methodSignature = [testObj methodSignatureForSelector:selector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
	invocation.target = testObj;
	float f135246 = 135.246;
	[invocation setSelector:selector];
	[invocation setArgument:&f135246 atIndex:2];

	DUIInvocation *duiInvocation = [[DUIInvocation alloc] initWithInvocation:invocation identifier:proxy.identifier];
    NSLog(@"Created Invocation: %@", duiInvocation);
    
	NSData *invocationData = [NSKeyedArchiver archivedDataWithRootObject:duiInvocation];
	DUIInvocation *unpackedInvocation = [NSKeyedUnarchiver unarchiveObjectWithData:invocationData];
    NSLog(@"Unpacked Invocation: %@", unpackedInvocation);
	XCTAssertEqualObjects(duiInvocation, unpackedInvocation, @"Unpacked invocation not equal to original.\nOriginal: %@\nUnpacked: %@", duiInvocation, unpackedInvocation);
}


// Tests distributed object management by adding unretained distributed objects and removing / releasing them
- (void) testUnretainedDistributedObjectManagement
{
	TestObject *testObj;
	NSUInteger objectCount;
	
	// Test un-retained object. Count should be 0 after testObj = nil since it is released immediately. We use an autorelease pool
	// since the weakly referenced objects might not be cleared from the DUI managers map table immediately
	@autoreleasepool {
		
		testObj = [[TestObject alloc] init];
		[dui addDistributedObject:testObj retain:NO];
		objectCount = dui.distributedObjectsCount;
		XCTAssert(objectCount == 1, @"Expected length 1 distributed objects array. Distributed Objects: %@", dui.distributedObjects);
		testObj = nil;
	}
	objectCount = dui.distributedObjectsCount;
	XCTAssert(objectCount == 0, @"Expected length 0 distributed objects array. Distributed Objects: %@", dui.distributedObjects);
}

// Tests distributed object management by adding retained distributed objects and removing / releasing them
- (void) testRetainedDistributedObjectManagement
{
	TestObject *testObj;
	NSUInteger objectCount;
	
	// Test retained object. Count should be 1 after testObj = nil since it is internally retained by the DUI manager. We use an autorelease pool
	// since the weakly referenced objects might not be cleared from the DUI managers map table immediately
	@autoreleasepool {
		
		// Test un-retained object. Count should be 1 after testObj = nil since it is retained by the manager
		testObj = [[TestObject alloc] init];
		[dui addDistributedObject:testObj retain:YES];
		testObj = nil;
	}
	objectCount = dui.distributedObjectsCount;
	XCTAssert(objectCount == 1, @"Expected length 1 distributed objects array. Distributed Objects: %@", dui.distributedObjects);
	
	[dui removeAllDistributedObjects];
	objectCount = dui.distributedObjectsCount;
	XCTAssert(objectCount == 0, @"Expected length 0 distributed objects array. Distributed Objects: %@", dui.distributedObjects);
}

@end
