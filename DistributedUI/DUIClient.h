//
//  DUIClient.h
//  DistributedUI
//
//  Created by Caleb Cannon on 12/6/13.
//  Copyright (c) 2013 Caleb Cannon. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DUIObjectProxy;

@protocol DUIDistrubtedObject <NSObject>

@end



@interface DUIClient : NSObject

/**
 Returns an array of proxies for local objects
*/
@property (readonly) NSArray *localObjectProxies;

/**
 Returns an array of proxies for remote objects
 */
@property (readonly) NSArray *remoteObjectProxies;

/**
 This method sets up a given object as a distributed object.  For each object added
 each remote device will initialize a DUObjectProxy for the given object.  Messages
 sent to those proxies will be propogated to the actual object and return values
 will be propogated back.
*/
- (void) addDistributedObject:(id<DUIDistrubtedObject>)object;

// Removes remote proxies for the given object
- (void) remoteDistributedObject:(id<DUIDistrubtedObject>)object;

@end
