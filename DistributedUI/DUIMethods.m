//
//  DUIMethods.m
//  DistributedUI
//
//  Created by Caleb Cannon on 12/8/13.
//  Copyright (c) 2013 Caleb Cannon All rights reserved.
//

//#import "DUIMethods.h"


struct DUIArgumentData_t {
	DUIArgumentType type;
	NSUInteger dataLength;					// For class objects this is the buffer length of the argument data. For c types it is the byte length of the data (sizeof(type))
	void *data;								// Buffer containing the argument data
} DUIArgumentData_t;
typedef struct DUIArgumentData_t * DUIArgumentDataRef;

struct DUIInvocationData_t {
	NSUInteger selectorNameLength;
	char *selectorName;						// A valid selector name (NSStringFromSelector) for the represented
	NSUInteger numberOfArguments;
	DUIArgumentDataRef *argumentData;		// An array of DUIArgumentDataRef
} DUIInvocationData_t;
typedef struct DUIInvocationData_t * DUIInvocationDataRef;

struct DUIMethodData_t {
	DUIInvocationDataRef invocationData;
	NSUInteger objectIdentifierLength;
	char *objectIdentifier;
} DUIMethodData_t;
typedef struct DUIMethodData_t * DUIMethodDataRef;



DUIMethodDataRef DUIMethodDataCreate(NSString *identifier, NSInvocation *invocation)
{
    DUIMethodDataRef methodData = malloc(sizeof(DUIMethodData_t));
    
    NSStringEncoding encoding = NSASCIIStringEncoding;
    NSUInteger length = [identifier lengthOfBytesUsingEncoding:encoding];
    methodData->objectIdentifier = malloc(sizeof(char)*length);
    [identifier getBytes:methodData->objectIdentifier
               maxLength:length
              usedLength:&methodData->objectIdentifierLength
                encoding:encoding
                 options:0
                   range:NSMakeRange(0, identifier.length)
          remainingRange:NULL];
    methodData->objectIdentifier[length] = 0;
    
    methodData->invocationData = DUIInvocationDataCreateWithInvocation(invocation);
    
    return methodData;
}

void DUIMethodDataRelease(DUIMethodDataRef method)
{
    DUIInvocationDataRelease(method->invocationData);
    free(method->objectIdentifier);
}

DUIInvocationDataRef DUIInvocationDataCreateWithInvocation(NSInvocation *invocation)
{
    // Get the selectorname and object identifier
    SEL selector = invocation.selector;
    NSString *selectorName = NSStringFromSelector(selector);
    
    DUIInvocationDataRef invocationData;
    invocationData = malloc(sizeof(DUIInvocationData_t));
    memset(invocationData, 0, sizeof(DUIInvocationData_t));
    
    // Get the selector name as a char string
    NSStringEncoding encoding = NSASCIIStringEncoding;
    NSUInteger length = [selectorName lengthOfBytesUsingEncoding:encoding];
    invocationData->selectorName = malloc(sizeof(char)*(length+1));
    [selectorName getBytes:invocationData->selectorName
                 maxLength:length
                usedLength:&invocationData->selectorNameLength
                  encoding:encoding
                   options:0
                     range:NSMakeRange(0, selectorName.length)
            remainingRange:NULL];
    invocationData->selectorName[length] = 0;
    
    // To gather the method parameters we use the method signature
    NSMethodSignature *methodSignature = invocation.methodSignature;
    
    // Iterate of the method arguments and add to the argument data->  The first
    // two arguments in obj-c methods are self and _cmd so we ignore them
    NSUInteger numberOfArguments = methodSignature.numberOfArguments - 2;
    invocationData->numberOfArguments = numberOfArguments;
    invocationData->argumentData = malloc(sizeof(DUIArgumentData_t)*numberOfArguments);
    
    for (NSUInteger argumentIndex = 0; argumentIndex < numberOfArguments; argumentIndex++)
    {   
        const char *argumentType = [methodSignature getArgumentTypeAtIndex:argumentIndex+2];

        // Note: getArgument:atIndex copies the argument data into the argumentBuffer. The buffer
        // 'must be large enough to contain the data' .. we are however dealing with basic types,
        // int, float, id, etc, so this buffer should be suffifient
        void *argumentBuffer = malloc(8);
        memset(argumentBuffer, 0, 8);
        [invocation getArgument:&argumentBuffer atIndex:argumentIndex+2];
        
        invocationData->argumentData[argumentIndex] = DUIArgmentDataCreate(argumentType, argumentBuffer);
    }
    
    return invocationData;
}


void DUIInvocationDataRelease(DUIInvocationDataRef invocationData)
{
    for (NSUInteger i = 0; i < invocationData->numberOfArguments; i++)
        DUIArgumentDataRelease(invocationData->argumentData[i]);
}

DUIArgumentDataRef DUIArgmentDataCreate(const char *argumentType, void *argument)
{
    DUIArgumentDataRef argumentData = malloc(sizeof(struct DUIArgumentData_t));
    memset(argumentData, 0, sizeof(DUIArgumentData_t));

    if (strcmp (argumentType, @encode (id)) == 0)
    {
        NSData *archivedArgumentData = [NSKeyedArchiver archivedDataWithRootObject:(__bridge id)argument];
        argumentData->type = DUIArgumentTypeObject;
        argumentData->dataLength = archivedArgumentData.length;
        argumentData->data = malloc(argumentData->dataLength);
        [archivedArgumentData getBytes:argumentData->data length:argumentData->dataLength];
    }
    else
    {
        // We compare the argument type with the encoding type of our supported base types. For each type,
        // will fill the the argumentData's type identifier and dataLength (sizeof(type)) value. Then
        // we copy create a buffer and copy actual data bytes based on the data type byte length
        // BOOL types use a minor hack -- @encode BOOL and char resolve to the same value. Added true/false
        // check for for 'booleans' This will fail for something like 'char c = YES'
        if (strcmp (argumentType, @encode (int)) == 0)
        {
            argumentData->type = DUIArgumentTypeInt;
            argumentData->dataLength = sizeof(int);
        }
        else if (strcmp (argumentType, @encode (float)) == 0)
        {
            argumentData->type = DUIArgumentTypeFloat;
            argumentData->dataLength = sizeof(float);
        }
        else if (strcmp (argumentType, @encode (NSInteger)) == 0)
        {
            argumentData->type = DUIArgumentTypeInteger;
            argumentData->dataLength = sizeof(NSInteger);
        }
        else if (strcmp (argumentType, @encode (NSUInteger)) == 0)
        {
            argumentData->type = DUIArgumentTypeUnsignedInteger;
            argumentData->dataLength = sizeof(NSUInteger);
        }
        else if (strcmp (argumentType, @encode (BOOL)) == 0 && ((BOOL)argument == TRUE || (BOOL)argument == FALSE))
        {
            argumentData->type = DUIArgumentTypeBoolean;
            argumentData->dataLength = sizeof(BOOL);
        }
        else if (strcmp (argumentType, @encode (char)) == 0)
        {
            argumentData->type = DUIArgumentTypeChar;
            argumentData->dataLength = sizeof(char);
        }
        else
        {
            // Invalid Type!
        }
        
        argumentData->data = malloc(argumentData->dataLength);
        memcpy(argumentData->data, &argument, argumentData->dataLength);
    }
    
    return argumentData;
}

void DUIArgumentDataRelease(DUIArgumentDataRef argumentData)
{
    free(argumentData->data);
    free(argumentData);
}

#pragma mark - Execution

void DUIMethodExecute(DUIMethodDataRef methodData)
{
    NSInvocation *invocation = NSInvocationFromDUIInvocationData(methodData->invocationData);
    
    // TODO: Get object based on identifier
    id object = nil;
    if (object)
        [invocation invokeWithTarget:object];
}

NSInvocation *NSInvocationFromDUIInvocationData(DUIInvocationDataRef invocationData)
{
    // Create a method signature from the selector name
    NSString *selectorName = [[NSString alloc] initWithBytes:invocationData->selectorName
                                                      length:invocationData->selectorNameLength
                                                    encoding:NSASCIIStringEncoding];
    SEL selector = NSSelectorFromString(selectorName);
    NSMethodSignature *methodSignature = [NSMethodSignature methodSignatureForSelector:selector];
    
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];

    return invocation;
}

#pragma mark Converting to strings

NSString *NSStringFromMethodData(DUIMethodDataRef method)
{
    NSMutableString *string = [NSMutableString string];
    [string appendFormat:@"Object identifier: %s\n", method->objectIdentifier];
    
    [string appendFormat:@"Invocation: %@", NSStringFromInvocationData(method->invocationData)];

    return string;
}

NSString *NSStringFromInvocationData(DUIInvocationDataRef invocationData)
{
    NSMutableString *string = [NSMutableString string];
    [string appendFormat:@"Selector: %s\n", invocationData->selectorName];
    
    if (invocationData->numberOfArguments > 0)
    {
        [string appendFormat:@"Arguments:\n"];
        for (NSUInteger i = 0; i < invocationData->numberOfArguments; i++)
        {
            DUIArgumentDataRef argument = invocationData->argumentData[i];
            [string appendFormat:@"\tArgument %lu: %@\n", (unsigned long)i, NSStringFromArgumentData(argument)];
        }
    }

    return string;
}

NSString *NSStringFromArgumentData(DUIArgumentDataRef argument)
{
    NSString *value = nil;
    
    void *data = argument->data;

    switch (argument->type)
    {
        case DUIArgumentTypeObject:
            value = [NSString stringWithFormat:@"%@", [NSKeyedUnarchiver unarchiveObjectWithData:[NSData dataWithBytes:data length:argument->dataLength]]];
            break;
        case DUIArgumentTypeInt:
            value = [NSString stringWithFormat:@"%i", (*(int*)data)];
            break;
        case DUIArgumentTypeFloat:
            value = [NSString stringWithFormat:@"%f", (*(float*)data)];
            break;
        case DUIArgumentTypeInteger:
            value = [NSString stringWithFormat:@"%li", (long)(*(NSInteger*)data)];
            break;
        case DUIArgumentTypeUnsignedInteger:
            value = [NSString stringWithFormat:@"%lu", (unsigned long)(*(NSUInteger*)data)];
            break;
        case DUIArgumentTypeChar:
            value = [NSString stringWithFormat:@"%c", (*(char*)data)];
            break;
        case DUIArgumentTypeBoolean:
            value = [NSString stringWithFormat:@"%i", (*(BOOL*)data)];
            break;
        default:
            value = @"Unknown Type";
    }
    
    return [NSString stringWithFormat:@"Type=%@ Length=%lu Value=%@",
            NSStringFromDUIArgumentType(argument->type), (unsigned long)argument->dataLength, value];
}

NSString *NSStringFromDUIArgumentType(DUIArgumentType type)
{
    switch (type) {
        case DUIArgumentTypeObject:
            return @"DUIArgumentTypeObject";
        case DUIArgumentTypeInt:
            return @"DUIArgumentTypeInt";
        case DUIArgumentTypeFloat:
            return @"DUIArgumentTypeFloat";
        case DUIArgumentTypeInteger:
            return @"DUIArgumentTypeInteger";
        case DUIArgumentTypeUnsignedInteger:
            return @"DUIArgumentTypeUnsignedInteger";
        case DUIArgumentTypeChar:
            return @"DUIArgumentTypeChar";
        case DUIArgumentTypeBoolean:
            return @"DUIArgumentTypeBoolean";
        default:
            return nil;
    }
}