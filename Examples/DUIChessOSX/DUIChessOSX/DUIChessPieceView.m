//
//  DUIChessPieceView.m
//  DUIChessOSX
//
//  Created by Caleb Cannon on 4/11/15.
//  Copyright (c) 2015 Caleb Cannon. All rights reserved.
//

#import "DUIChessPieceView.h"


@interface DUIChessPieceView ()
{
	BOOL dragging;
	NSPoint dragOffset;
}

@end


@implementation DUIChessPieceView

@synthesize piece = _piece;

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
	self.image = [NSImage imageNamed:imageName];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	// Start dragging
	CGPoint mousePoint = [theEvent locationInWindow];
	NSPoint frameOrigin = self.frame.origin;
	dragOffset = NSMakePoint(mousePoint.x - frameOrigin.x, mousePoint.y - frameOrigin.y);
	
	[self.superview addSubview:self positioned:NSWindowAbove relativeTo:nil];	
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	CGPoint mousePoint = [theEvent locationInWindow];
	
	NSPoint frameOrigin = NSMakePoint(mousePoint.x - dragOffset.x,
									  mousePoint.y - dragOffset.y);
	
	[self setFrameOrigin:frameOrigin];
}


- (void)mouseUp:(NSEvent *)theEvent
{
	dragging = NO;
	if ([self.delegate respondsToSelector:@selector(chessPieceViewDidEndDragging:)])
		[self.delegate chessPieceViewDidEndDragging:self];
}

@end
