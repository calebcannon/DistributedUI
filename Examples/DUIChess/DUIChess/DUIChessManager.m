//
//  DUIChessManager.m
//  DUIChess
//
//  Created by Caleb Cannon on 3/19/14.
//  Copyright (c) 2014 Caleb Cannon. All rights reserved.
//

#import "DUIChessManager.h"


NSString * const DUIChessManagerDidStartNewGame = @"DUIChessManagerDidStartNewGame";
NSString * const DUIChessManagerBoardPositionChanged = @"DUIChessManagerBoardPositionChanged";
NSString * const DUIChessManagerGameStateChanged = @"DUIChessManagerGameStateChanged";



@interface DUIChessManager ()
{
	DUIChessPiece chessBoard[8][8];
}

@property (assign) DUIChessGameState gameState;

@end



@implementation DUIChessManager

@synthesize gameState = _gameState;

SYNTHESIZE_SHARED_SINGLETON(DUIChessManager, sharedInstance)

- (id)init
{
	self = [super init];
	if (self)
	{
		[self newgame];
	}
	return self;
}

- (void)newgame
{
	_gameState = DUIChessGameStateWhitesTurn;

	// Create a game board and copy it into the actual board state
	DUIChessPiece chessBoardC[][8] = {
		{ DUIChessPieceBlackRookR, DUIChessPieceBlackPawnA, DUIChessPieceNone, DUIChessPieceNone, DUIChessPieceNone, DUIChessPieceNone, DUIChessPieceWhitePawnA, DUIChessPieceWhiteRookR },
		{ DUIChessPieceBlackKnightR, DUIChessPieceBlackPawnB, DUIChessPieceNone, DUIChessPieceNone, DUIChessPieceNone, DUIChessPieceNone, DUIChessPieceWhitePawnB, DUIChessPieceWhiteKnightR },
		{ DUIChessPieceBlackBishopR, DUIChessPieceBlackPawnC, DUIChessPieceNone, DUIChessPieceNone, DUIChessPieceNone, DUIChessPieceNone, DUIChessPieceWhitePawnC, DUIChessPieceWhiteBishopR },
		{ DUIChessPieceBlackQueen, DUIChessPieceBlackPawnD, DUIChessPieceNone, DUIChessPieceNone, DUIChessPieceNone, DUIChessPieceNone, DUIChessPieceWhitePawnD, DUIChessPieceWhiteQueen },
		{ DUIChessPieceBlackKing, DUIChessPieceBlackPawnE, DUIChessPieceNone, DUIChessPieceNone, DUIChessPieceNone, DUIChessPieceNone, DUIChessPieceWhitePawnE, DUIChessPieceWhiteKing },
		{ DUIChessPieceBlackBishopL, DUIChessPieceBlackPawnF, DUIChessPieceNone, DUIChessPieceNone, DUIChessPieceNone, DUIChessPieceNone, DUIChessPieceWhitePawnF, DUIChessPieceWhiteBishopL },
		{ DUIChessPieceBlackKnightL, DUIChessPieceBlackPawnG, DUIChessPieceNone, DUIChessPieceNone, DUIChessPieceNone, DUIChessPieceNone, DUIChessPieceWhitePawnG, DUIChessPieceWhiteKnightL },
		{ DUIChessPieceBlackRookL, DUIChessPieceBlackPawnH, DUIChessPieceNone, DUIChessPieceNone, DUIChessPieceNone, DUIChessPieceNone, DUIChessPieceWhitePawnH, DUIChessPieceWhiteRookL },
	};
	memcpy(chessBoard, chessBoardC, sizeof(DUIChessPiece)*8*8);
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DUIChessManagerDidStartNewGame object:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:DUIChessManagerBoardPositionChanged object:self];
}

- (NSDictionary *)boardState
{
	NSMutableDictionary *boardState = [NSMutableDictionary dictionary];
	for (NSUInteger x = 0; x < 8; x++)
	{
		for (NSUInteger y = 0; y < 8; y++)
		{
			if (chessBoard[x][y] != DUIChessPieceNone)
			{
				NSString *key = PositionFromXY((char)x, (int)y);
				NSNumber *piece = [NSNumber numberWithInteger:chessBoard[x][y]];
				[boardState setObject:piece forKey:key];
			}
		}
	}
	
	return boardState;
}

- (void)setGameState:(DUIChessGameState)gameState
{
	if (_gameState != gameState)
	{
		_gameState = gameState;
		[[NSNotificationCenter defaultCenter] postNotificationName:DUIChessManagerGameStateChanged object:self];
	}
}

- (DUIChessGameState)gameState
{
	return _gameState;
}

- (BOOL) movePieceAtPosition:(NSString *)position toPosition:(NSString *)destination;
{
	if (![self canMovePieceAtPosition:position toPosition:destination])
	{
		// Post this notification anyway so that the board state is reset.  TODO: Change the notification or reset the board the right way
		[[NSNotificationCenter defaultCenter] postNotificationName:DUIChessManagerBoardPositionChanged object:self];
		return NO;
	}
	
	int x1 = XFromPosition(position);
	int y1 = YFromPosition(position);
	int x2 = XFromPosition(destination);
	int y2 = YFromPosition(destination);
	
	// Move the piece and clear the old position
	chessBoard[x2][y2] = chessBoard[x1][y1];
	chessBoard[x1][y1] = DUIChessPieceNone;

	[[NSNotificationCenter defaultCenter] postNotificationName:DUIChessManagerBoardPositionChanged object:self];
	
	return YES;
}

- (BOOL) canMovePieceAtPosition:(NSString *)position toPosition:(NSString *)destination;
{
	int x1 = XFromPosition(position);
	int y1 = YFromPosition(position);
	int x2 = XFromPosition(destination);
	int y2 = YFromPosition(destination);
	
	if (x1 == x2 && y1 == y2)
		return NO;
	
	if (x1 < 0 || x1 >= 8 || y1 < 0 || y1 >= 8 || x2 < 0 || x2 >= 8 || y2 < 0 || y2 >= 8)
		return NO;
	
	DUIChessPiece piece1 = chessBoard[x1][y1];
	DUIChessPiece piece2 = chessBoard[x2][y2];

	int pieceColor1 = piece1 & DUIChessPieceColorMask;
	int pieceColor2 = piece2 & DUIChessPieceColorMask;

	if (pieceColor1 == pieceColor2 && piece1 != DUIChessPieceNone && piece2 != DUIChessPieceNone)
		return NO;
	
	// TODO: Implement move logic for various pieces and valid position checking
	
	return YES;
}

- (BOOL)movePiece:(DUIChessPiece)piece toPosition:(NSString *)destination
{
	NSString *position = [self positionForPiece:piece];
	if (position)
		return [self movePieceAtPosition:position toPosition:destination];
	else
		

	return NO;
}

- (NSString *) positionForPiece:(DUIChessPiece)piece
{
	for (NSUInteger x = 0; x < 8; x++)
		for (NSUInteger y = 0; y < 8; y++)
			if (chessBoard[x][y] == piece)
				return PositionFromXY((char)x, (int)y);
	
	return nil;
}

@end



NSString *NSStringFromDUIChessPiece(DUIChessPiece piece)
{
	NSString *color = (piece & DUIChessPieceWhiteMask) ? @"White" : @"Black";
	NSString *name = (piece & DUIChessPiecePawnMask) ? @"Pawn" :
					 (piece & DUIChessPieceKnightMask) ? @"Knight" :
					 (piece & DUIChessPieceBishopMask) ? @"Bishop" :
					 (piece & DUIChessPieceRookMask) ? @"Rook" :
					 (piece & DUIChessPieceQueenMask) ? @"Queen" : @"King";

	return [NSString stringWithFormat:@"%@ %@", color, name];
}