//
//  DUObjectProxy.h
//  DistributedUI
//
//  Created by Caleb Cannon on 12/6/13.
//  Copyright (c) 2013 Caleb Cannon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DUIObjectProxy : NSProxy

@property (readonly) Class representedClass;

@end
