//
//  GameBoardScoreTracker.m
//  Chainz
//
//  Created by Pedro Gomes on 12/27/11.
//  Copyright (c) 2011 Phluid Labs. All rights reserved.
//

#import "GameBoardScoreTracker.h"

////////////////////////////////////////////////////////////////////////////////
// Constants and Definitions
////////////////////////////////////////////////////////////////////////////////
const NSUInteger kMinChainSize				= 3;	// minimum chain size to increase the score
const NSUInteger kMinChainScore 			= 100;	// score for the minChainSize with no multipliers
const NSUInteger kScorePerExtraGem			= 50;	// add this much for every chain size unit above the minimum

const NSUInteger kMinNumberOfStreaksToScoreCombo	= 3;	// if the player accumulates this much streaks, we enter a combo mode
const NSTimeInterval kMaxIntervalToCountAsStreak	= 0.2; //  this is the maximum time that can occur between scoring events in order for the event to count as streak

////////////////////////////////////////////////////////////////////////////////
// Helper functions
////////////////////////////////////////////////////////////////////////////////
static inline NSUInteger ComputeChainScore(NSArray *chain, float multiplier)
{
	NSUInteger chainSize = [chain count];
	if(chainSize < kMinChainSize) {
		return 0;
	}
	
	// (MinimumScore + (ExtraScoreForEveryUnitAboveMinimum)) * CurrentMultiplier
	return (kMinChainScore + ((chainSize - kMinChainSize) * kScorePerExtraGem)) * multiplier;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface GameBoardScoreTracker()

- (void)_checkForStreak;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation GameBoardScoreTracker

@synthesize delegate = _delegate;

#pragma mark - Dealloc and Initialization

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)dealloc
{
	self.delegate = nil;
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (id)initWithDelegate:(id<GameBoardScoreTrackerDelegate>)delegate
{
	if((self = [super init])) {
		_flags.delegateRespondsToDidStreak			= [self.delegate respondsToSelector:@selector(scoreTracker:didStreak:)];
		_flags.delegateRespondsToDidUpdateScore 	= [self.delegate respondsToSelector:@selector(scoreTracker:didUpdateScore:)];
		_flags.delegateRespondToDidScoreChain 		= [self.delegate respondsToSelector:@selector(scoreTracker:didScoreChain:withMultiplier:)];
		_flags.delegateRespondsToDidScoreCombochain = [self.delegate respondsToSelector:@selector(scoreTracker:didScoreComboChain:withMultiplier:)];
		self.delegate = delegate;
		
		_numberOfStreaks = 0;
		_scoreMultiplier = 1;
		_lastScoredAt = [[NSDate date] timeIntervalSinceDate:[NSDate distantPast]];
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (id)initWithGameBoard:(GameBoard *)board
{
	if((self = [super init])) {
		_board = board;
	}
	return self;
}

#pragma mark - Public Methods

////////////////////////////////////////////////////////////////////////////////
// We can try to promote fast gameplay by also increasing the multiplier when
// the player scores various single chains within a very short interval (berzerk/frantic mode!)
////////////////////////////////////////////////////////////////////////////////
- (void)scoreChain:(NSArray *)chain
{
	[self _checkForStreak];
	
	double chainScore = ComputeChainScore(chain, _scoreMultiplier);
	_score += chainScore;
	
	if(_flags.delegateRespondToDidScoreChain) {
		[self.delegate scoreTracker:self didScoreChain:chainScore withMultiplier:_scoreMultiplier];
	}
	if(_flags.delegateRespondsToDidUpdateScore) {
		[self.delegate scoreTracker:self didUpdateScore:_score];
	}
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)scoreComboChain:(NSArray *)chain
{
	_scoreMultiplier++;
	
	double chainScore = ComputeChainScore(chain, _scoreMultiplier);
	_score += chainScore;
	
	if(_flags.delegateRespondsToDidScoreCombochain) {
		[self.delegate scoreTracker:self didScoreComboChain:chainScore withMultiplier:_scoreMultiplier];
	}
	if(_flags.delegateRespondsToDidUpdateScore) {
		[self.delegate scoreTracker:self didUpdateScore:_score];
	}
}

#pragma mark - Private Methods

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)_checkForStreak
{
	NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
	if(now - _lastScoredAt < kMaxIntervalToCountAsStreak) {
		_numberOfStreaks++;
	}
	else {
		_numberOfStreaks = 0;
		_scoreMultiplier = 1;
	}
	
	if(_numberOfStreaks >= kMinNumberOfStreaksToScoreCombo) {
		_scoreMultiplier++;
		if(_flags.delegateRespondsToDidStreak) {
			[self.delegate scoreTracker:self didStreak:_numberOfStreaks];
		}
	}
}

@end
