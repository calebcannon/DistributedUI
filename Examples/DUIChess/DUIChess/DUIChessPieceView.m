//
//  DUIChessPieceView.m
//  DUIChess
//
//  Created by Caleb Cannon on 3/19/14.
//  Copyright (c) 2014 Caleb Cannon. All rights reserved.
//

#import "DUIChessPieceView.h"

@interface DUIChessPieceView ()
{
	BOOL dragging;
}

@end



@implementation DUIChessPieceView

@synthesize piece = _piece;

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
	{
		self.userInteractionEnabled = YES;
	}
	return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	dragging = YES;
	[self.superview bringSubviewToFront:self];
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	if (!dragging)
		return;
	
	// Simple touch+drag operation
	
	UITouch *touch = [touches anyObject];
	
	CGPoint point = [touch locationInView:self.superview];
	CGPoint previousPoint = [touch previousLocationInView:self.superview];
	
	CGPoint delta = CGPointMake(previousPoint.x - point.x, previousPoint.y - point.y);
	
	self.frame = CGRectMake(self.frame.origin.x - delta.x, self.frame.origin.y - delta.y, self.frame.size.width, self.frame.size.height);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	dragging = NO;
	if ([self.delegate respondsToSelector:@selector(chessPieceViewDidEndDragging:)])
		[self.delegate chessPieceViewDidEndDragging:self];
}

- (DUIChessPiece)piece
{
	return _piece;
}

- (void)setPiece:(DUIChessPiece)piece
{
	_piece = piece;
	
	// Update the display image
	
	NSString *color = (piece & DUIChessPieceWhiteMask) ? @"White" : @"Black";
	NSString *shape;
	if (piece & DUIChessPiecePawnMask)
		shape = @"Pawn";
	if (piece & DUIChessPieceKingMask)
		shape = @"King";
	if (piece & DUIChessPieceQueenMask)
		shape = @"Queen";
	if (piece & DUIChessPieceRookMask)
		shape = @"Rook";
	if (piece & DUIChessPieceBishopMask)
		shape = @"Bishop";
	if (piece & DUIChessPieceKnightMask)
		shape = @"Knight";
	
	NSString *imageName = [NSString stringWithFormat:@"%@ %@", color, shape];
	self.image = [UIImage imageNamed:imageName];
}

@end
