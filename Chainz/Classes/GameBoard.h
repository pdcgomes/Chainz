//
//  GameBoard.h
//  Chainz
//
//  Created by Pedro Gomes on 12/13/11.
//  Copyright (c) 2011 Phluid Labs. All rights reserved.
//

#import "CCSprite.h"
@class Gem;
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#define GAMEBOARD_NUM_ROWS	8
#define GAMEBOARD_NUM_COLS	8

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface GameBoard : CCSprite
{
	NSInteger			_board[GAMEBOARD_NUM_COLS][GAMEBOARD_NUM_ROWS];
	NSMutableDictionary	*_validMoves;
}

- (void)resetGameBoard;
- (void)swapGemAtPoint:(CGPoint)gem1 withGemAtPoint:(CGPoint)gem2;

- (void)clearChain:(CGPoint)point sequence:(NSArray *)sequence;
- (void)siftDownGemsAboveClearedCells;
- (void)generateGemsForClearedCells;

- (void)simulateGameplay;
- (void)printBoard;

@end
