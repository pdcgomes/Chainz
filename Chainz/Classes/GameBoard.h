//
//  GameBoard.h
//  Chainz
//
//  Created by Pedro Gomes on 12/13/11.
//  Copyright (c) 2011 Phluid Labs. All rights reserved.
//

#import "cocos2d.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
typedef enum {
	GameboardMovementDirectionLeft,
	GameboardMovementDirectionRight,
	GameboardMovementDirectionUp,
	GameboardMovementDirectionDown,
	GameboardMovementDirectionInvalid,
} GameboardMovementDirection;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#define GAMEBOARD_NUM_ROWS	8
#define GAMEBOARD_NUM_COLS	8

extern const NSInteger 	kGameboardNumberOfRows;
extern const NSInteger 	kGameboardNumberOfCols;
extern const CGSize		kGameboardCellSize;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@class Gem;
@interface GameBoard : CCLayer
{
	BOOL					_initialized;
	NSInteger				_board[GAMEBOARD_NUM_COLS][GAMEBOARD_NUM_ROWS];
	NSMutableArray			*_gems;
	NSMutableDictionary		*_validMovesLookupTable;
	
	// test code
	NSMutableArray			*_gemDestructionQueue;
	NSMutableArray			*_gemDropdownQueue;
	NSMutableArray			*_gemGenerationQueue;
}

- (void)resetGameBoard;
- (void)swapGemAtPoint:(CGPoint)gem1 withGemAtPoint:(CGPoint)gem2;
- (BOOL)moveGemAtPoint:(CGPoint)point withDirection:(GameboardMovementDirection)direction;

- (void)clearChain:(CGPoint)point sequence:(NSArray *)sequence;
- (void)generateGemsForClearedCells;

- (void)simulateGameplay;
- (void)printBoard;

@end
