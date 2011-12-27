//
//  GameBoardScoreTracker.h
//  Chainz
//
//  Created by Pedro Gomes on 12/27/11.
//  Copyright (c) 2011 Phluid Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@class GameBoard;
@protocol GameBoardScoreTrackerDelegate;
@interface GameBoardScoreTracker : NSObject
{
	__weak GameBoard					*_board;
	double								_score;
	float								_scoreMultiplier;
	NSUInteger							_numberOfStreaks;
	NSTimeInterval						_lastScoredAt;

	id<GameBoardScoreTrackerDelegate>	_delegate;
	struct {
		unsigned delegateRespondsToDidUpdateScore:1;
		unsigned delegateRespondToDidScoreChain:1;
		unsigned delegateRespondsToDidScoreCombochain:1;
	} _flags;
}

@property (nonatomic, assign) id<GameBoardScoreTrackerDelegate> delegate;

- (id)initWithDelegate:(id<GameBoardScoreTrackerDelegate>)delegate;
- (id)initWithGameBoard:(GameBoard *)board;

- (void)scoreChain:(NSArray *)chain;
- (void)scoreComboChain:(NSArray *)chain;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol GameBoardScoreTrackerDelegate <NSObject>

@required
- (void)scoreTracker:(GameBoardScoreTracker *)tracker didUpdateScore:(double)score;
- (void)scoreTracker:(GameBoardScoreTracker *)tracker didScoreChain:(double)score withMultiplier:(float)multiplier;
- (void)scoreTracker:(GameBoardScoreTracker *)tracker didScoreComboChain:(double)score withMultiplier:(float)multiplier;


@end


