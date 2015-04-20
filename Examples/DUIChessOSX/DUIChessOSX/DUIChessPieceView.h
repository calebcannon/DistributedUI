//
//  DUIChessPieceView.h
//  DUIChessOSX
//
//  Created by Caleb Cannon on 4/11/15.
//  Copyright (c) 2015 Caleb Cannon. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "DUIChessManager.h"

@class DUIChessPieceView;


@protocol DUIChessPieceViewDelegate <NSObject>

- (void) chessPieceViewDidEndDragging:(DUIChessPieceView *)view;

@end


@interface DUIChessPieceView : NSImageView

@property (assign) DUIChessPiece piece;

@property (weak) id<DUIChessPieceViewDelegate> delegate;

@end
