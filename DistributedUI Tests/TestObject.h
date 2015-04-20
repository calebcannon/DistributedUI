//
//  TestObject.h
//  DistributedUI
//
//  Created by Caleb Cannon on 12/23/13.
//  Copyright (c) 2013 Caleb Cannon. All rights reserved.
//

@import Foundation;

@interface TestObject : NSObject

+ (instancetype)accessorMethodName;

- (void) doSomeStuffWithAString:(NSString *)aString;
- (void) doSomeStuffWithAFloat:(float)aFloat;
- (void) doSomeStuffWithAnInt:(int)anInt;
- (void) doSomeStuffWithABool:(BOOL)aBool;
- (void) doSomeStuffWithAChar:(char)aChar;
- (void) doSomeStuffWithAString:(NSString *)aString anInt:(int)anInt aFloat:(float)aFloat aBool:(BOOL)aBool aChar:(char)aChar;
- (void) doSomeStuff;

- (NSString *) getAString;
- (float) getAFloat;
- (int) getAnInt;
- (BOOL) getABool;
- (char) getAChar;

- (int) multiplyByTwo:(int)input;

- (char) theLetterC;
- (char) theLetterG;
- (float) pi;
- (int) theMeaningOfLife;
- (NSString *) theAuthorsFirstName;

@end
