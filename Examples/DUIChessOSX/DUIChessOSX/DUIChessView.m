//
//  DUIChessView.m
//  DUIChessOSX
//
//  Created by Caleb Cannon on 4/11/15.
//  Copyright (c) 2015 Caleb Cannon. All rights reserved.
//


#import "DUIChessView.h"
#import "DUIChessPieceView.h"


@interface DUIChessView () <DUIChessPieceViewDelegate>

@property (strong) NSDictionary *boardState;

@end


@implementation DUIChessView

@synthesize boardState = _boardState;

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self)
	{
		[[DUIManager sharedDUIManager] addDistributedNotificationObserver:self
																 selector:@selector(boardPositionChanged:)
																	 name:DUIChessManagerBoardPositionChanged
																   object:nil];
		
		self.boardState = [[DUIChessManager sharedInstance] boardState];

		[self layoutAnimated:NO];
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
	
	CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
	
	CGRect boardFrame = [self boardFrame];
	CGFloat squareSize = [self squareSize];
	
	NSImage *blackSquare = [NSImage imageNamed:@"Black Square"];
	NSImage *whiteSquare = [NSImage imageNamed:@"White Square"];
	CGAffineTransform transform;
	
	for (int x = 0; x < 8; x++)
	{
		for (int y = 0; y < 8; y++)
		{
			// Translate to position
			transform = CGAffineTransformMakeTranslation(x*squareSize+boardFrame.origin.x,
														 y*squareSize+boardFrame.origin.y);
			
			// Rotate about square center
			transform = CGAffineTransformTranslate(transform, squareSize/2.0, squareSize/2.0);
			switch ((x + y + (x)/(y+3)*73)%4)
			{
				case 1:
					transform = CGAffineTransformRotate(transform, M_PI/2.0);
					break;
				case 2:
					transform = CGAffineTransformRotate(transform, M_PI);
					break;
				case 3:
					transform = CGAffineTransformRotate(transform, 3.0*M_PI/2.0);
					break;
				default:
					break;
			}
			transform = CGAffineTransformTranslate(transform, -squareSize/2.0, -squareSize/2.0);
			
			// Save GState and apply transform
			CGContextSaveGState(ctx);
			CGContextConcatCTM(ctx, transform);
			
			// Draw the square
			if ((x+y)%2 == 0)
				[blackSquare drawInRect:CGRectMake(0, 0, squareSize, squareSize)];
			else
				[whiteSquare drawInRect:CGRectMake(0, 0, squareSize, squareSize)];
			
			// Restore GState
			CGContextRestoreGState(ctx);
		}
	}
}

- (CGRect) boardFrame
{
	CGRect bounds = self.bounds;
	CGFloat maxSize = MIN(bounds.size.width, bounds.size.height);
	CGRect boardFrame = CGRectMake((bounds.size.width-maxSize)/2.0,
								   (bounds.size.height-maxSize)/2.0,
								   maxSize,
								   maxSize);
	return boardFrame;
}

- (CGFloat) squareSize
{
	CGRect bounds = self.bounds;
	CGFloat maxSize = MIN(bounds.size.width, bounds.size.height);
	CGFloat squareSize = maxSize/8.0;
	return squareSize;
}

- (void)setFrame:(NSRect)frame
{
	[super setFrame:frame];
	[self layoutAnimated:NO];
}

- (void)layoutAnimated:(BOOL)animated
{
	// -boardState returns a dictionary with the piece positions
	// stored as the dictionary keys in chess coordinate notation
	CGRect boardFrame = [self boardFrame];
	CGFloat squareSize = [self squareSize];
	
	DUIChessPiece piece;
	int x, y;
	
	for (NSString *key in [self.boardState allKeys])
	{
		piece = [[self.boardState objectForKey:key] intValue];
		x = XFromPosition(key);
		y = YFromPosition(key);
		
		// Inverted coords on MacOS
		y = 7-y;
		
		DUIChessPieceView *pieceView = [self viewForPiece:piece];
		if (animated)
			pieceView = pieceView.animator;
		pieceView.frame = CGRectMake(x*squareSize+boardFrame.origin.x, y*squareSize+boardFrame.origin.y, squareSize, squareSize);
	}
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (DUIChessPieceView *) viewForPiece:(DUIChessPiece)piece
{
	for (DUIChessPieceView *pieceView in self.subviews)
		if (pieceView.piece == piece)
			return pieceView;
	
	DUIChessPieceView *pieceView = [[DUIChessPieceView alloc] initWithFrame:CGRectZero];
	pieceView.piece = piece;
	pieceView.delegate = self;
	[self addSubview:pieceView];
	return pieceView;
}

- (void)chessPieceViewDidEndDragging:(DUIChessPieceView *)view
{
	CGRect boardFrame = [self boardFrame];
	
	// Get the X/Y for the dragged piece position
	CGPoint center = CGPointMake(CGRectGetMidX(view.frame), CGRectGetMidY(view.frame));
	int x = floor((center.x - boardFrame.origin.x)/boardFrame.size.width*8);
	int y = floor((center.y - boardFrame.origin.y)/boardFrame.size.height*8);
	
	// Inverted coords on MacOS
	y = 7-y;
	
	NSString *destination = PositionFromXY(x, y);
	
	[[DUIChessManager sharedInstance] movePiece:view.piece toPosition:destination];
}

- (void)setBoardState:(NSDictionary *)boardState
{
	[self setBoardState:boardState animated:NO];
}

- (NSDictionary *)boardState
{
	return _boardState;
}

- (void)setBoardState:(NSDictionary *)boardState animated:(BOOL)animated
{
	_boardState = boardState;
	
	if (animated)
	{
		for (DUIChessPieceView *pieceView in self.subviews)
		{
			if (![[self.boardState allValues] containsObject:[NSNumber numberWithUnsignedInteger:pieceView.piece]])
			{
				[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
					pieceView.animator.frame = CGRectMake(pieceView.frame.origin.x + pieceView.frame.size.width/2.0, pieceView.frame.origin.y + pieceView.frame.size.height/2.0, 0, 0);
				} completionHandler:^{
					[pieceView removeFromSuperview];
				}];
			}
		}
	}
	
	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		[self layoutAnimated:YES];
	} completionHandler:nil];
}

- (void) boardPositionChanged:(NSNotification *)notification
{
	NSDictionary *boardState = [[DUIChessManager sharedInstance] boardState];
	[self setBoardState:boardState
			   animated:YES];
}

@end
