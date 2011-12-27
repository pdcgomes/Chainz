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
	return (kMinChainScore + (([chain count] - kMinChainSize) * kScorePerExtraGem)) * multiplier;
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
////////////////////////////////////////////////////////////////////////////////
- (void)scoreChain:(NSArray *)chain
{
	_multiplier = 1;
	
	double chainScore = ComputeChainScore(chain, 1);
	_score += chainScore;
	
	if(_flags.delegateRespondToDidScoreChain) {
		[self.delegate scoreTracker:self didScoreChain:chainScore withMultiplier:_multiplier];
	}
	if(_flags.delegateRespondsToDidUpdateScore) {
		[self.delegate scoreTracker:self didUpdateScore:_score];
	}
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)scoreComboChain:(NSArray *)chain
{
	_multiplier++;
	
	double chainScore = ComputeChainScore(chain, _multiplier);
	_score += chainScore;
	
	if(_flags.delegateRespondsToDidScoreCombochain) {
		[self.delegate scoreTracker:self didScoreComboChain:chainScore withMultiplier:_multiplier];
	}
	if(_flags.delegateRespondsToDidUpdateScore) {
		[self.delegate scoreTracker:self didUpdateScore:_score];
	}
}

#pragma mark - Private Methods

@end
