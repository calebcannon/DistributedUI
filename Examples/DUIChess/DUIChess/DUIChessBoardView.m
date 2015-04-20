//
//  DUIChessBoardView.m
//  DUIChess
//
//  Created by Caleb Cannon on 3/19/14.
//  Copyright (c) 2014 Caleb Cannon. All rights reserved.
//

#import "DUIChessBoardView.h"
#import "DUIChessManager.h"
#import "DUIChessPieceView.h"


@interface DUIChessBoardView () <DUIChessPieceViewDelegate>

@property (strong) NSDictionary *boardState;

@end


@implementation DUIChessBoardView

@synthesize boardState = _boardState;

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self)
	{
		self.contentMode = UIViewContentModeCenter;
		[[DUIManager sharedDUIManager] addDistributedNotificationObserver:self
																 selector:@selector(boardPositionChanged:)
																	 name:DUIChessManagerBoardPositionChanged
																   object:nil];
		
		self.boardState = [[DUIChessManager sharedInstance] boardState];
	}
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)drawRect:(CGRect)rect
{
	[super drawRect:rect];
	
	CGRect boardFrame = [self boardFrame];
	CGFloat squareSize = [self squareSize];

	
	UIImage *blackSquare = [UIImage imageNamed:@"Black Square"];
	UIImage *whiteSquare = [UIImage imageNamed:@"White Square"];
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
			CGContextSaveGState(UIGraphicsGetCurrentContext());
			CGContextConcatCTM(UIGraphicsGetCurrentContext(), transform);
			
			// Draw the square
			if ((x+y)%2 == 1)
				[blackSquare drawInRect:CGRectMake(0, 0, squareSize, squareSize)];
			else
				[whiteSquare drawInRect:CGRectMake(0, 0, squareSize, squareSize)];
			
			// Restore GState
			CGContextRestoreGState(UIGraphicsGetCurrentContext());
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

- (void)layoutSubviews
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
		
		DUIChessPieceView *pieceView = [self viewForPiece:piece];
		pieceView.frame = CGRectMake(x*squareSize+boardFrame.origin.x, y*squareSize+boardFrame.origin.y, squareSize, squareSize);
	}
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
	CGPoint center = view.center;
	int x = floor((center.x - boardFrame.origin.x)/boardFrame.size.width*8);
	int y = floor((center.y - boardFrame.origin.y)/boardFrame.size.height*8);
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

	//NSLog(@"Board State: %@", self.boardState);

	CGFloat duration = (animated) ? 0.2 : 0.0;
	if (animated)
	for (DUIChessPieceView *pieceView in self.subviews)
	{
		if (![[self.boardState allValues] containsObject:[NSNumber numberWithInteger:pieceView.piece]])
		{
			[UIView animateWithDuration:duration
							 animations:^{
								 pieceView.frame = CGRectMake(pieceView.frame.origin.x + pieceView.frame.size.width/2.0, pieceView.frame.origin.y + pieceView.frame.size.height/2.0, 0, 0);
							 }
							 completion:^(BOOL completed) {
								 [pieceView removeFromSuperview];
							 }];
		}
	}
	
	[UIView animateWithDuration:duration animations:^{ [self layoutSubviews]; }];
}

- (void) boardPositionChanged:(NSNotification *)notification
{
	NSDictionary *boardState = [[DUIChessManager sharedInstance] boardState];
	[self setBoardState:boardState
			   animated:YES];
}

@end
