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
const NSUInteger kMinChainSize		= 3;
const NSUInteger kMinChainScore 	= 100;
const NSUInteger kScorePerExtraGem	= 50;

////////////////////////////////////////////////////////////////////////////////
// Helper functions
////////////////////////////////////////////////////////////////////////////////
static inline NSUInteger ComputeChainScore(NSArray *chain, float multiplier)
{
	NSUInteger chainSize = [chain count];
	if(chainSize < kMinChainSize) {
		return 0;
	}
	return (kMinChainScore + ((chainSize - kMinChainSize) * kScorePerExtraGem)) * multiplier;
}

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
		_flags.delegateRespondsToDidUpdateScore 	= [self.delegate respondsToSelector:@selector(scoreTracker:didUpdateScore:)];
		_flags.delegateRespondToDidScoreChain 		= [self.delegate respondsToSelector:@selector(scoreTracker:didScoreChain:withMultiplier:)];
		_flags.delegateRespondsToDidScoreCombochain = [self.delegate respondsToSelector:@selector(scoreTracker:didScoreComboChain:withMultiplier:)];
		self.delegate = delegate;
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
	NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
	if(now - _lastScoredAt < 0.2) {
		_numberOfStreaks++;
	}
	else {
		_numberOfStreaks = 0;
		_scoreMultiplier = 1;
	}
	
	if(_numberOfStreaks >= 3) {
		_scoreMultiplier++;
		// notify delegate of streak
	}
	
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

@end
