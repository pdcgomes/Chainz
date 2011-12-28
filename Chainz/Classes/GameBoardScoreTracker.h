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
	NSUInteger							_score;
	NSUInteger							_scoreMultiplier;
	NSUInteger							_numberOfStreaks;
	NSTimeInterval						_lastScoredAt;

	id<GameBoardScoreTrackerDelegate>	_delegate;
	struct {
		unsigned delegateRespondsToDidStreak:1;
		unsigned delegateRespondsToDidUpdateScore:1;
		unsigned delegateRespondToDidScoreChain:1;
		unsigned delegateRespondsToDidScoreCombochain:1;
	} _flags;
}

@property (nonatomic, assign) id<GameBoardScoreTrackerDelegate> delegate;
@property (nonatomic, readonly) NSUInteger score;

- (id)initWithDelegate:(id<GameBoardScoreTrackerDelegate>)delegate;
- (id)initWithGameBoard:(GameBoard *)board;

- (NSUInteger)scoreChain:(NSArray *)chain;
- (NSUInteger)scoreComboChain:(NSArray *)chain;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@protocol GameBoardScoreTrackerDelegate <NSObject>

@required

- (void)scoreTracker:(GameBoardScoreTracker *)tracker didStreak:(NSUInteger)streaks;
- (void)scoreTracker:(GameBoardScoreTracker *)tracker didUpdateScore:(NSUInteger)score;
- (void)scoreTracker:(GameBoardScoreTracker *)tracker didScoreChain:(NSUInteger)score withMultiplier:(NSUInteger)multiplier;
- (void)scoreTracker:(GameBoardScoreTracker *)tracker didScoreComboChain:(NSUInteger)score withMultiplier:(NSUInteger)multiplier;


@end


