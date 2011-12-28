//
//  GameBoard.h
//  Chainz
//
//  Created by Pedro Gomes on 12/13/11.
//  Copyright (c) 2011 Phluid Labs. All rights reserved.
//

#import "cocos2d.h"
#import "GameBoardScoreTracker.h"

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
@class GameBoardSolver;
@interface GameBoard : CCLayer
{
	BOOL					_initialized;
	NSInteger				_board[GAMEBOARD_NUM_COLS][GAMEBOARD_NUM_ROWS];
	GameBoardSolver			*_solver;
	GameBoardScoreTracker	*_scoreTracker;
	NSMutableArray			*_gems;
	NSMutableDictionary		*_validMovesLookupTable; // stores all legal swaps for a given point
	NSMutableDictionary		*_legalMovesLookupTable; // stores the legality of every valid swap combination
	
	// test code
	NSMutableArray			*_gemDestructionQueue;
	NSMutableArray			*_gemDropdownQueue;
	NSMutableArray			*_gemGenerationQueue;
	
	Gem						*_selectedGem;
}

@property (nonatomic, readonly) GameBoardScoreTracker *scoreTracker;

- (void *)board;

- (void)resetGameBoard;
- (void)swapGemAtPoint:(CGPoint)gem1 withGemAtPoint:(CGPoint)gem2;
- (BOOL)moveGemAtPoint:(CGPoint)point withDirection:(GameboardMovementDirection)direction;
- (void)selectGem:(Gem *)gem;

- (void)clearChain:(CGPoint)point sequence:(NSArray *)sequence;
- (void)clearChain:(CGPoint)point sequence:(NSArray *)sequence combo:(BOOL)isCombo;

- (void)generateGemsForClearedCells;

- (void)simulateGameplay;
- (void)printBoard;

@end
