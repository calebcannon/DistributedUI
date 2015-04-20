//
//  DUIChessPieceView.h
//  DUIChess
//
//  Created by Caleb Cannon on 3/19/14.
//  Copyright (c) 2014 Caleb Cannon. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DUIChessManager.h"

@class DUIChessPieceView;



@protocol DUIChessPieceViewDelegate <NSObject>

- (void) chessPieceViewDidEndDragging:(DUIChessPieceView *)view;

@end



@interface DUIChessPieceView : UIImageView

@property (assign) DUIChessPiece piece;

@property (weak) id<DUIChessPieceViewDelegate> delegate;

@end
