//
//  DUIMethods.h
//  DistributedUI
//
//  Created by Caleb Cannon on 12/8/13.
//  Copyright (c) 2013 Caleb Cannon. All rights reserved.
//

@import Foundation;


// This struct is used to contain method and argument data when forwarding invocations over the network.

typedef NS_ENUM(NSUInteger, DUIArgumentType) {
    DUIArgumentTypeUnknown = 0,				// Unknown type -- usually an error condition
    DUIArgumentTypeObject = 1,				// class id - must be immutable and implement NSCoding
    DUIArgumentTypeInt,						// int
    DUIArgumentTypeFloat,					// float
    DUIArgumentTypeInteger,					// NSInteger
    DUIArgumentTypeUnsignedInteger,			// NSUInteger
    DUIArgumentTypeChar,					// char
    DUIArgumentTypeBoolean					// BOOL
};


struct DUIArgumentData_t;
typedef struct DUIArgumentData_t * DUIArgumentDataRef;

struct DUIInvocationData_t;
typedef struct DUIInvocationData_t * DUIInvocationDataRef;

struct DUIMethodData_t;
typedef struct DUIMethodData_t * DUIMethodDataRef;


#pragma mark - Invocation Data Methods

DUIMethodDataRef DUIMethodDataCreate(NSString *, NSInvocation *);
void DUIMethodDataRelease(DUIMethodDataRef);

DUIInvocationDataRef DUIInvocationDataCreateWithInvocation(NSInvocation *);
void DUIInvocationDataRelease(DUIInvocationDataRef);

DUIArgumentDataRef DUIArgmentDataCreate(const char *, void *);
void DUIArgumentDataRelease(DUIArgumentDataRef);



#pragma mark -

void DUIMethodExecute(DUIMethodDataRef);
NSInvocation *NSInvocationFromDUIInvocationData(DUIInvocationDataRef invocationData);



#pragma mark -

NSString *NSStringFromMethodData(DUIMethodDataRef method);
NSString *NSStringFromInvocationData(DUIInvocationDataRef invocation);
NSString *NSStringFromArgumentData(DUIArgumentDataRef argument);
NSString *NSStringFromDUIArgumentType(DUIArgumentType type);