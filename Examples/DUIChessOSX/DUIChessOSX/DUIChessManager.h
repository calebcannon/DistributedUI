//
//  DUIChessManager.h
//  DUIChess
//
//  Created by Caleb Cannon on 3/19/14.
//  Copyright (c) 2014 Caleb Cannon. All rights reserved.
//

@import Foundation;
@import DistributedUI;

/*
 Basic chess implementation -- provides storage for a configuration, functions for
 moving pieces, and testing for end states
*/

// Sent when -newgame is called
extern NSString * const DUIChessManagerDidStartNewGame;

// Sent whenever the -boardState has changed
extern NSString * const DUIChessManagerBoardPositionChanged;

// Send whenever the -gameState has changed
extern NSString * const DUIChessManagerGameStateChanged;

// Enumerant type used to represent chess pieces / board states. We use masks to make piece identification/comparison a bitwise operation
typedef NS_ENUM(NSUInteger, DUIChessPiece)
{
	DUIChessPieceNone = 0,

	DUIChessPieceWhiteMask		= 0x00001000,
	DUIChessPieceBlackMask		= 0x00002000,
	
	DUIChessPieceKingMask		= 0x00100000,
	DUIChessPieceQueenMask		= 0x00200000,
	DUIChessPieceRookMask		= 0x00400000,
	DUIChessPieceBishopMask		= 0x00800000,
	DUIChessPieceKnightMask		= 0x00010000,
	DUIChessPiecePawnMask		= 0x00020000,

	DUIChessPieceWhiteKing		= DUIChessPieceWhiteMask | DUIChessPieceKingMask,
	DUIChessPieceWhiteQueen		= DUIChessPieceWhiteMask | DUIChessPieceQueenMask,
	DUIChessPieceWhiteRookR		= DUIChessPieceWhiteMask | DUIChessPieceRookMask | 0x00000001,
	DUIChessPieceWhiteRookL		= DUIChessPieceWhiteMask | DUIChessPieceRookMask | 0x00000002,
	DUIChessPieceWhiteBishopR	= DUIChessPieceWhiteMask | DUIChessPieceBishopMask | 0x00000001,
	DUIChessPieceWhiteBishopL	= DUIChessPieceWhiteMask | DUIChessPieceBishopMask | 0x00000002,
	DUIChessPieceWhiteKnightR	= DUIChessPieceWhiteMask | DUIChessPieceKnightMask | 0x00000001,
	DUIChessPieceWhiteKnightL	= DUIChessPieceWhiteMask | DUIChessPieceKnightMask | 0x00000002,
	DUIChessPieceWhitePawnA		= DUIChessPieceWhiteMask | DUIChessPiecePawnMask | 0x00000001,
	DUIChessPieceWhitePawnB		= DUIChessPieceWhiteMask | DUIChessPiecePawnMask | 0x00000002,
	DUIChessPieceWhitePawnC		= DUIChessPieceWhiteMask | DUIChessPiecePawnMask | 0x00000004,
	DUIChessPieceWhitePawnD		= DUIChessPieceWhiteMask | DUIChessPiecePawnMask | 0x00000008,
	DUIChessPieceWhitePawnE		= DUIChessPieceWhiteMask | DUIChessPiecePawnMask | 0x00000010,
	DUIChessPieceWhitePawnF		= DUIChessPieceWhiteMask | DUIChessPiecePawnMask | 0x00000020,
	DUIChessPieceWhitePawnG		= DUIChessPieceWhiteMask | DUIChessPiecePawnMask | 0x00000040,
	DUIChessPieceWhitePawnH		= DUIChessPieceWhiteMask | DUIChessPiecePawnMask | 0x00000080,

	DUIChessPieceBlackKing		= DUIChessPieceBlackMask | DUIChessPieceKingMask,
	DUIChessPieceBlackQueen		= DUIChessPieceBlackMask | DUIChessPieceQueenMask,
	DUIChessPieceBlackRookR		= DUIChessPieceBlackMask | DUIChessPieceRookMask | 0x00000001,
	DUIChessPieceBlackRookL		= DUIChessPieceBlackMask | DUIChessPieceRookMask | 0x00000002,
	DUIChessPieceBlackBishopR	= DUIChessPieceBlackMask | DUIChessPieceBishopMask | 0x00000001,
	DUIChessPieceBlackBishopL	= DUIChessPieceBlackMask | DUIChessPieceBishopMask | 0x00000002,
	DUIChessPieceBlackKnightR	= DUIChessPieceBlackMask | DUIChessPieceKnightMask | 0x00000001,
	DUIChessPieceBlackKnightL	= DUIChessPieceBlackMask | DUIChessPieceKnightMask | 0x00000002,
	DUIChessPieceBlackPawnA		= DUIChessPieceBlackMask | DUIChessPiecePawnMask | 0x00000001,
	DUIChessPieceBlackPawnB		= DUIChessPieceBlackMask | DUIChessPiecePawnMask | 0x00000002,
	DUIChessPieceBlackPawnC		= DUIChessPieceBlackMask | DUIChessPiecePawnMask | 0x00000004,
	DUIChessPieceBlackPawnD		= DUIChessPieceBlackMask | DUIChessPiecePawnMask | 0x00000008,
	DUIChessPieceBlackPawnE		= DUIChessPieceBlackMask | DUIChessPiecePawnMask | 0x00000010,
	DUIChessPieceBlackPawnF		= DUIChessPieceBlackMask | DUIChessPiecePawnMask | 0x00000020,
	DUIChessPieceBlackPawnG		= DUIChessPieceBlackMask | DUIChessPiecePawnMask | 0x00000040,
	DUIChessPieceBlackPawnH		= DUIChessPieceBlackMask | DUIChessPiecePawnMask | 0x00000080,
};

NSString *NSStringFromDUIChessPiece(DUIChessPiece piece);

// Enumerant type returned by -gameState
typedef NS_ENUM(NSUInteger, DUIChessGameState)
{
	DUIChessGameStateWhitesTurn,
	DUIChessGameStateBlacksTurn,
	DUIChessGameStateWhiteWins,
	DUIChessGameStateBlackWins,
	DUIChessGameStateDraw,
};

// Macros for converting between x,y positions and chess coordinate notation
#define PositionFromXY(x, y) [NSString stringWithFormat:@"%c%i", x+65, y]
#define XFromPosition(position) ([position characterAtIndex:0] - 65)
#define YFromPosition(position) ([position characterAtIndex:1] - 48)


@interface DUIChessManager : NSObject

DECLARE_SHARED_SINGLETON(DUIChessManager, sharedInstance)

// Returns the board state with positions mapped to piece types. E.g, @{ @"F5" : DUIChessPieceKing }.
// Spaces not having keys in the returned dictionary are understood to be unoccupied
@property (readonly, copy) NSDictionary *boardState;

// Moves the piece at the given position to the destination. Parameters are in coordinate form,
// e.g., [chessMan movePieceAtPosition:@"F5" toPosition:@"E6"]. Returns FALSE if the attempted
// move is invalid
- (BOOL) movePiece:(DUIChessPiece)piece toPosition:(NSString *)destination;
- (BOOL) movePieceAtPosition:(NSString *)position toPosition:(NSString *)destination;
- (BOOL) canMovePieceAtPosition:(NSString *)position toPosition:(NSString *)destination;

// Gets the position in board coordinates for the given piece or nil if the piece has been captured
- (NSString *) positionForPiece:(DUIChessPiece)piece;

// Returns the state of the current game
@property (readonly) DUIChessGameState gameState;

// Starts a new game and resets the state and position
- (void) newgame;

@end
