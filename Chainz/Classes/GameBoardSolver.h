//
//  GameBoardSolver.h
//  Chainz
//
//  Created by Pedro Gomes on 12/27/11.
//  Copyright (c) 2011 Phluid Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GameBoard.h"

////////////////////////////////////////////////////////////////////////////////
// Decouples all board solving logic from the Gameboard itself
// this allows us to hide the implementation of the underlying algorithms
////////////////////////////////////////////////////////////////////////////////
@interface GameBoardSolver : NSObject
{
	NSUInteger				_board[GAMEBOARD_NUM_COLS][GAMEBOARD_NUM_ROWS];
	NSMutableDictionary		*_validMovesLookupTable; // stores all legal swaps for a given point
	NSMutableDictionary		*_legalMovesLookupTable; // stores the legality of every valid swap combination
}

// Ensure the board state is updated
- (void)updateBoard:(NSUInteger[GAMEBOARD_NUM_COLS][GAMEBOARD_NUM_ROWS])state;

- (BOOL)isLegalMove:(CGPoint)p1 p2:(CGPoint)p2;

- (NSArray *)findAllChainsFromPoint:(CGPoint)point;
- (NSMutableDictionary *)findAllChains;
- (NSDictionary *)findAllValidMoves;

@end
