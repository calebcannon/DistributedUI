//
//  XCTestCase+AsyncTesting.h
//  AsyncXCTestingKit
//
//  Created by 小野 将司 on 12/03/17.
//  Modified for XCTest by Vincil Bishop
//  Copyright (c) 2012年 AppBankGames Inc. All rights reserved.
//

#import <XCTest/XCTest.h>


enum {
    XCTAsyncTestCaseStatusUnknown = 0,
    XCTAsyncTestCaseStatusWaiting,
    XCTAsyncTestCaseStatusSucceeded,
    XCTAsyncTestCaseStatusFailed,
    XCTAsyncTestCaseStatusCancelled,
};
typedef NSInteger XCTAsyncTestCaseStatus;

void XCTAssertNotificationReceived(NSString *name, id sender, NSTimeInterval duration, NSString *format, ...);

@interface XCTestCase (AsyncTesting)

- (void)waitForStatus:(XCTAsyncTestCaseStatus)status timeout:(NSTimeInterval)timeout;
- (void)waitForTimeout:(NSTimeInterval)timeout;
- (void)notify:(XCTAsyncTestCaseStatus)status;

@end