//
//  DistributedUI_Tests.m
//  DistributedUI Tests
//
//  Created by Caleb Cannon on 12/22/13.
//  Copyright (c) 2013 Caleb Cannon. All rights reserved.
//

#import <XCTest/XCTest.h>

@import Foundation;
@import UIKit;

#import "DistributedUI.h"
#import "TestObject.h"

#import <objc/runtime.h>

@interface DUIManager ()

+ (void) setSharedDUIManager:(DUIManager *)manager;

@end


@interface DistributedUI_Tests : XCTestCase
{
	DUIManager *duiHost;
	DUIManager *duiRemote;
}

@end


@implementation DistributedUI_Tests


- (void)setUp
{
    [super setUp];
	
	NSLog(@"\n------------------------------------------------\nSetup\n------------------------------------------------\n\n");

	duiHost = [DUIManager new];
	duiHost.serviceName = @"Distributed UI Host";
	duiHost.isHost = YES;
	[DUIManager setSharedDUIManager:duiHost];
	
	duiRemote = [DUIManager new];
	duiRemote.serviceName = @"Distributed UI Remote";
	duiRemote.isHost = NO;
		
	[duiHost startDistributedInterfaceSession];
	[duiRemote startDistributedInterfaceSession];
	
	XCTAssertNotificationReceived(DUIManagerFoundPeerNotification, duiRemote, 5.0, @"Service discovery failed");
	
	NSLog(@"Connecting to Available Services: %@", duiRemote.availableServices);
	for (DUINetService *service in duiRemote.availableServices)
	{
		[service connect];
		XCTAssertNotificationReceived(DUINetServiceDidConnect, service, 5.0, @"Service failed to connect", service);
		NSLog(@"Connected!");
	}
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


- (void) testRegistration
{
	// Register the test object
	[duiHost registerSingletonClass:[TestObject class] selector:@selector(accessorMethodName)];
	[duiRemote registerSingletonClass:[TestObject class] selector:@selector(accessorMethodName)];
	
	TestObject *testObj = [TestObject accessorMethodName];
	
	DUIObjectIdentifier *identifier = [duiHost addDistributedObject:testObj retain:NO];

	// TODO: Get remote and local test servers connecting. Get addDistObj above to register with remote end (remote ends for host)
	// Get remote end to forward send method response over netwk
	DUINetService *service = nil;
	if (duiRemote.availableServices.count > 0)
		service = duiRemote.availableServices[0];
	
	DUIRemoteObjectProxy *remoteProxy = [[DUIRemoteObjectProxy alloc] initWithIdentifier:identifier service:service];
	
//	[service sendObject:@"Testing"];
//	[service sendObject:@"Testing 1 2 3"];
	
//	DUIRemoteObjectProxy *remoteProxy = [duiRemote remoteObjectProxyForIdentifier:identifier];
	
	char C = 'C';
	char G = 'G';
	float pi = M_PI;

	char theLetterC = [(id)remoteProxy theLetterC];
	XCTAssertEqual(theLetterC, C, @"theLetterC function failed to return value");

	char theLetterG = [(id)remoteProxy theLetterG];
	XCTAssertEqual(theLetterG, G, @"theLetterG function failed to return value");
	
	int theMeaningOfLife = [(id)remoteProxy theMeaningOfLife];
	XCTAssertEqual(theMeaningOfLife, 42, @"theMeaningOfLife function failed to return value");

	float somePi = [(id)remoteProxy pi];
	XCTAssertEqual(somePi, pi, @"pi function failed to return value");

	int twentySix = [(id)remoteProxy multiplyByTwo:13];
	XCTAssertEqual(twentySix, 26, @"multiplyByTwo function failed to return value");
	
	int twoFiftyFour = [(id)remoteProxy multiplyByTwo:127];
	XCTAssertEqual(twoFiftyFour, 254, @"multiplyByTwo function failed to return value");

	NSString *Caleb = [(id)remoteProxy theAuthorsFirstName];
	XCTAssertEqualObjects(Caleb, @"Caleb", @"theAuthorsFirstName function failed to return value");
}


@end
