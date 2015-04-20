//
//  DUIIdentifier.h
//  DistributedUI
//
//  Created by Caleb Cannon on 12/27/13.
//  Copyright (c) 2013 Caleb Cannon. All rights reserved.
//




@interface DUIIdentifier : NSObject <NSCoding, NSCopying>

// Create a new unique identifier
+ (instancetype) identifier;

- (BOOL)isEqualToIdentifier:(DUIIdentifier *)identifier;

@end



@interface DUIObjectIdentifier : DUIIdentifier <NSCoding, NSCopying>

@property (readonly, copy) NSString *representedClassName;

// Create an identifier for the given object. If class is null the object class is inferred as [object class]
+ (instancetype) identifierForObject:(id)object representedClass:(Class)objectClass;

@end



@interface DUISingletonIdentifier : DUIObjectIdentifier <NSCoding, NSCopying>

// Creates a unique identifier for the singleton based object class. This identifier can be used to retrieve
// a global 'shared' instance of the singleton from DUI client instances
+ (instancetype) identifierForSingletonWithClass:(Class)objectClass;

@end