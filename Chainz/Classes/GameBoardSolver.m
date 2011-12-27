//
//  GameBoardSolver.m
//  Chainz
//
//  Created by Pedro Gomes on 12/27/11.
//  Copyright (c) 2011 Phluid Labs. All rights reserved.
//

#import "GameBoardSolver.h"

////////////////////////////////////////////////////////////////////////////////
// Constants and definitions
////////////////////////////////////////////////////////////////////////////////
static const NSUInteger 	kGameboardMinSequence 	= 3;

#define VALID_CELL(x,y) (x >= 0 && x < GAMEBOARD_NUM_COLS && y >= 0 && y < GAMEBOARD_NUM_ROWS)
#define LEFT_CELL(x,y) (VALID_CELL(x-1, y) ? _board[x-1][y] : GemColorInvalid)
#define RIGHT_CELL(x,y) (VALID_CELL(x+1, y) ? _board[x+1][y] : GemColorInvalid)
#define ABOVE_CELL(x,y) (VALID_CELL(x,y-1) ? _board[x][y-1] : GemColorInvalid)
#define BELOW_CELL(x,y) (VALID_CELL(x,y+1) ? _board[x][y+1] : GemColorInvalid)

#define ASSERT_VALID_CELL(point) do { NSAssert1(VALID_CELL(point.x, point.y), @"Invalid cell %@", NSStringFromCGPoint(node)); } while(0)

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface GameBoardSolver()

- (NSArray *)_floodFill:(CGPoint)node color:(NSInteger)color;
- (NSArray *)_findAllChainsForSequence:(NSArray *)sequence;
- (NSDictionary *)_findAllSequences;;

- (void)_updateLegalMoves;
- (BOOL)_isLegalMove:(CGPoint)p1 p2:(CGPoint)p2;
- (void)_markMove:(CGPoint)point1 to:(CGPoint)point2 legal:(BOOL)legal;
- (BOOL)_lookupMove:(CGPoint)point1 toPoint:(CGPoint)point2;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation GameBoardSolver

#pragma mark - Dealloc and Initialization

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)dealloc
{
	[_validMovesLookupTable release];
	[_legalMovesLookupTable release];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (id)init
{
	if((self = [super init])) {
		_validMovesLookupTable = [[NSMutableDictionary alloc] init];
		_legalMovesLookupTable = [[NSMutableDictionary alloc] init];
	}
	return self;
}

#pragma mark - Public Methods

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)updateBoard:(NSUInteger[GAMEBOARD_NUM_COLS][GAMEBOARD_NUM_ROWS])state
{
	memcpy(_board, state, sizeof(NSUInteger)*GAMEBOARD_NUM_COLS*GAMEBOARD_NUM_ROWS);
	[self _updateLegalMoves];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSArray *)findAllChainsFromPoint:(CGPoint)point
{
	NSArray *sequences = [self _floodFill:point color:_board[(NSInteger)point.x][(NSInteger)point.y]];
	return [self _findAllChainsForSequence:sequences];
}

////////////////////////////////////////////////////////////////////////////////
// Inspects the whole board and returns a list of all current chains 
// [source_point] => [list of points that comprise the chain]
////////////////////////////////////////////////////////////////////////////////
- (NSMutableDictionary *)findAllChains
{
	NSUInteger x, y;
	NSMutableDictionary *matchesByPos = [[NSMutableDictionary alloc] init];
	for(x = 0; x < GAMEBOARD_NUM_COLS; x++) {
		for(y = 0; y < GAMEBOARD_NUM_ROWS; y++) {
			NSArray *sequence = [self _floodFill:(CGPoint){x, y} color:_board[x][y]];
			if([sequence count] == 0) continue;
			
			NSArray *chains = [self _findAllChainsForSequence:sequence];
			if([chains count] == 0) continue;
			
			[matchesByPos setObject:chains forKey:NSStringFromCGPoint((CGPoint){x,y})];
		}
	}
	return [matchesByPos autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// Inspects the whole board and returns a collection of all valid moves:
// [point] => [list of all valid adjacent swaps]
// NOTE: consider turning this in an updateAllValidMoves method and cache the results
// any subsequent movement attempt would only require a dictionary lookup
// after all chains are processed, we would invoke this method agan to recompute
// all valid moves - this would also make the job of handing tips to the user a lot easier
////////////////////////////////////////////////////////////////////////////////
- (NSDictionary *)findAllValidMoves
{
	[self _updateLegalMoves];
	return _validMovesLookupTable;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)isLegalMove:(CGPoint)p1 p2:(CGPoint)p2
{
	return [self _isLegalMove:p1 p2:p2];
}

#pragma mark - Private Methods

////////////////////////////////////////////////////////////////////////////////
// At the moment, at least in my head, it makes sense to separate the flood fill
// from the actual code that determines if there are valid chains
// Since the flood fill is all about finding sequences of matching colors given
// an origin point, we can then work from there and find which sequences are 
// actually triggering some game event
// What this actually does:
//	given a starting point, finds all adjacent points with the same color
//	we perform the same operation for every matching point
//	if we matched at least 3 points (including the source) we return them
////////////////////////////////////////////////////////////////////////////////
- (NSArray *)_floodFill:(CGPoint)node color:(NSInteger)color
{
	ASSERT_VALID_CELL(node);
	
	NSMutableArray *matches = [[NSMutableArray alloc] init];
	NSMutableArray *queue = [[NSMutableArray alloc] init];
	[queue addObject:NSStringFromCGPoint(node)];
	
	NSMutableDictionary *visitedNodes = [[NSMutableDictionary alloc] init];
	
	while([queue count] > 0) {
		NSString *nodeKey = [queue objectAtIndex:0];
		[queue removeObjectAtIndex:0];
		
		CGPoint p = CGPointFromString(nodeKey);
		NSInteger x = (NSUInteger)p.x;
		NSInteger y = (NSUInteger)p.y;
		
		if([visitedNodes objectForKey:nodeKey]) {
			continue;
		}
		else {
			[visitedNodes setObject:[NSNull null] forKey:nodeKey];
		}
		
		if(_board[x][y] == color) {
			[matches addObject:NSStringFromCGPoint(p)];
		}
		
		NSInteger cursor = x-1;
		if(cursor >= 0 && _board[cursor][y] == color) {
			[queue addObject:NSStringFromCGPoint((CGPoint){cursor, y})];
			cursor--;
		}
		
		cursor = x+1;
		if(cursor < GAMEBOARD_NUM_ROWS && _board[cursor][y] == color) {
			[queue addObject:NSStringFromCGPoint((CGPoint){cursor, y})];
			cursor++;
		}
		
		cursor = y-1;
		if(cursor >= 0 && _board[x][cursor] == color) {
			[queue addObject:NSStringFromCGPoint((CGPoint){x, cursor})];
			cursor--;
		}
		
		cursor = y+1;
		if(cursor < GAMEBOARD_NUM_COLS && _board[x][cursor] == color) {
			[queue addObject:NSStringFromCGPoint((CGPoint){x, cursor})];
			cursor++;
		}
	}
	[queue release];
	[visitedNodes release];
	
	// This stage we don't really  care if the matching adjacent cells actually translate to a valid move
	// It's unlikely that we'll every need to match less than 3 cells, but in the future we may want to match diagonals, L shapes, etc.
	// We we'll implement the validation algorithm elsewhere
	// e.g.
	// [ 1] [ 2] [ 2]
	// [ 1] [ 1] [ 0]
	// [ 3] [ 3] [ 3]
	// This would match (0,0), (0,1), (1,1) (color = 1) and (0,2) (1,2) (2,2) (color = 3)
	// typical bejeweled rules would only translate to one valid chain (color 3)
	// again, we'll implement the game logic validation elsewhere
	if([matches count] < kGameboardMinSequence) {
		[matches removeAllObjects];
	}
	return [matches autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// Given the result of applying the FloodFill algorithm to a given point
// find all valid chains (given our game rules, every sequence of 3 or more columns or rows)
//
// TODO: modify to allow a reference point to be passed. The resulting chain must contain
// the point
////////////////////////////////////////////////////////////////////////////////
- (NSArray *)_findAllChainsForSequence:(NSArray *)sequence
{
	//	NSLog(@"***** FINDING ALL VALID CHAINS *****");
	//	NSLog(@"sequence = %@", sequence);
	
	// First we'll sort all points by X and by Y
	
	// Sort sequence by X
	NSArray *sortedByColumns = [sequence sortedArrayWithOptions:NSSortStable usingComparator:(NSComparator)^(id obj1, id obj2) {
		CGPoint p1 = CGPointFromString(obj1);
		CGPoint p2 = CGPointFromString(obj2);
		
		NSComparisonResult result;
		if(p1.x == p2.x) {
			if(p1.y < p2.y)			result = NSOrderedAscending;
			else if(p1.y > p2.y)	result = NSOrderedDescending;
			else 					result = NSOrderedSame;
		}
		else if(p1.x < p2.x) 		result = NSOrderedAscending;
		else 						result = NSOrderedDescending;
		return result;
	}];
	//	NSLog(@"sortedByColumns = %@", sortedByColumns);
	
	// Sort sequence by Y
	NSArray *sortedByRows = [sequence sortedArrayWithOptions:NSSortStable usingComparator:(NSComparator)^(id obj1, id obj2) {
		CGPoint p1 = CGPointFromString(obj1);
		CGPoint p2 = CGPointFromString(obj2);
		
		NSComparisonResult result;
		if(p1.y == p2.y) {
			if(p1.x < p2.x) 		result = NSOrderedAscending;
			else if(p1.x > p2.x) 	result = NSOrderedDescending;
			else 					result = NSOrderedSame;
		}
		if(p1.y < p2.y) 			result = NSOrderedAscending;
		else 						result = NSOrderedDescending;
		
		return result;
	}];
	//	NSLog(@"sortedByRows = %@", sortedByRows);
	
	NSMutableArray *chain = [[NSMutableArray alloc] init];
	NSMutableArray *tmpStack = [[NSMutableArray alloc] init];
	
	// ensure we have at least kGameboardMinSequence contiguous points on the same column
	CGFloat prevX = -1;
	for(NSString *pv in sortedByColumns) {
		CGPoint p = CGPointFromString(pv);
		if(p.x != prevX) {
			if([tmpStack count] >= kGameboardMinSequence) {
				[chain addObjectsFromArray:tmpStack];
			}
			[tmpStack removeAllObjects];
		}
		[tmpStack addObject:pv];
		prevX = p.x;
	}
	if([tmpStack count] >= kGameboardMinSequence) {
		[chain addObjectsFromArray:tmpStack];	
	}
	[tmpStack removeAllObjects];
	
	// ensure we have at least kGameboardMinSequence contiguous points on the same row
	CGFloat prevY = -1;
	for(NSString *pv in sortedByRows) {
		CGPoint p = CGPointFromString(pv);
		if(p.y != prevY) {
			if([tmpStack count] >= kGameboardMinSequence) {
				[chain addObjectsFromArray:tmpStack];
			}
			[tmpStack removeAllObjects];
		}
		[tmpStack addObject:pv];
		prevY = p.y;
	}
	if([tmpStack count] >= kGameboardMinSequence) {
		[chain addObjectsFromArray:tmpStack];	
	}
	[tmpStack release];
	
	//	NSLog(@"chain = %@", chain);
	
	return [chain autorelease];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSDictionary *)_findAllSequences
{
//	[self printBoard];
	
	NSUInteger x, y;
	BOOL visited[GAMEBOARD_NUM_ROWS][GAMEBOARD_NUM_COLS];
	for(x = 0; x < GAMEBOARD_NUM_COLS; x++) {
		for(y = 0; y < GAMEBOARD_NUM_ROWS; y++) {
			visited[x][y] = NO;
		}
	}
	
	NSMutableDictionary *matchesByPos = [[NSMutableDictionary alloc] init];
	for(x = 0; x < GAMEBOARD_NUM_COLS; x++) {
		for(y = 0; y < GAMEBOARD_NUM_ROWS; y++) {
			NSArray *matches = [self _floodFill:(CGPoint){x, y} color:_board[x][y]];
			if([matches count] > 0) {
				[matchesByPos setObject:matches forKey:NSStringFromCGPoint((CGPoint){x,y})];
			}
		}
	}
	return [matchesByPos autorelease];
}

#pragma mark - 

////////////////////////////////////////////////////////////////////////////////
// Note: this needs optimizing, we're currently doing a lot of redundant checks
////////////////////////////////////////////////////////////////////////////////
- (void)_updateLegalMoves
{
	[_validMovesLookupTable removeAllObjects];
	[_legalMovesLookupTable removeAllObjects];
	
	NSUInteger x, y;
	for(x = 0; x < GAMEBOARD_NUM_COLS; x++) {
		for(y = 0; y < GAMEBOARD_NUM_ROWS; y++) {
			NSMutableArray *movesForPoint = [[NSMutableArray alloc] initWithCapacity:4];
			CGPoint p = (CGPoint){x, y};
			if([self _isLegalMove:p p2:(CGPoint){x+1, y}]) { // swap with right gem
				[movesForPoint addObject:NSStringFromCGPoint((CGPoint){x+1, y})];
			}
			if([self _isLegalMove:p p2:(CGPoint){x-1, y}]) { // swap with left gem
				[movesForPoint addObject:NSStringFromCGPoint((CGPoint){x-1, y})];
			}
			if([self _isLegalMove:p p2:(CGPoint){x, y+1}]) { // swap with gem below
				[movesForPoint addObject:NSStringFromCGPoint((CGPoint){x, y+1})];
			}
			if([self _isLegalMove:p p2:(CGPoint){x, y-1}]) { // swap with gem above
				[movesForPoint addObject:NSStringFromCGPoint((CGPoint){x, y-1})];
			}
			if([movesForPoint count] > 0) {
				[_validMovesLookupTable setObject:movesForPoint forKey:NSStringFromCGPoint(p)];
			}
			[movesForPoint release];
		}
	}
}

////////////////////////////////////////////////////////////////////////////////
// 
////////////////////////////////////////////////////////////////////////////////
- (void)_markMove:(CGPoint)point1 to:(CGPoint)point2 legal:(BOOL)legal
{
	NSString *point1Str = NSStringFromCGPoint(point1);
	NSString *point2Str = NSStringFromCGPoint(point2);
	
	void (^updateLookupTableBlock)(NSString *fromPoint, NSString *toPoint, BOOL legal);
	updateLookupTableBlock = ^(NSString *fromPointStr, NSString *toPointStr, BOOL legal) {
		NSString *key = [NSString stringWithFormat:@"%@-%@", fromPointStr, toPointStr];
		[_legalMovesLookupTable setObject:[NSNumber numberWithBool:legal] forKey:key];
	};
	
	updateLookupTableBlock(point1Str, point2Str, legal);
	updateLookupTableBlock(point2Str, point1Str, legal);
}

////////////////////////////////////////////////////////////////////////////////
// Checks whether a given move was already computed (marked)
////////////////////////////////////////////////////////////////////////////////
- (BOOL)_lookupMove:(CGPoint)point1 toPoint:(CGPoint)point2
{
	NSString *point1Str = NSStringFromCGPoint(point1);
	NSString *point2Str = NSStringFromCGPoint(point2);
	
	NSString *key = [NSString stringWithFormat:@"%@-%@", point1Str, point2Str];
	return [_legalMovesLookupTable objectForKey:key] != nil;
}

////////////////////////////////////////////////////////////////////////////////
// Checks whether performing a p1 <-> p2 swap would result in a valid move
////////////////////////////////////////////////////////////////////////////////
- (BOOL)_isLegalMove:(CGPoint)p1 p2:(CGPoint)p2
{
	if([self _lookupMove:p1 toPoint:p2]) {
		NSString *lookupKey = [NSString stringWithFormat:@"%@-%@", NSStringFromCGPoint(p1), NSStringFromCGPoint(p2)];
		return [[_legalMovesLookupTable objectForKey:lookupKey] boolValue];
	}
	
	CGRect bounds = CGRectMake(0, 0, GAMEBOARD_NUM_COLS, GAMEBOARD_NUM_ROWS);
	BOOL gameboardContainsPoints = CGRectContainsPoint(bounds, p1) && CGRectContainsPoint(bounds, p2);
	if(!gameboardContainsPoints) {
		return NO;
	}
	
	CC_SWAP(_board[(NSInteger)p1.x][(NSInteger)p1.y], _board[(NSInteger)p2.x][(NSInteger)p2.y]);
	
	NSArray *p1Sequences = [self _floodFill:p1 color:_board[(NSInteger)p1.x][(NSInteger)p1.y]];
	NSArray *p2Sequences = [self _floodFill:p2 color:_board[(NSInteger)p2.x][(NSInteger)p2.y]];	
	
	NSArray *p1Chain = [self _findAllChainsForSequence:p1Sequences];
	NSArray *p2Chain = [self _findAllChainsForSequence:p2Sequences];
	
	CC_SWAP(_board[(NSInteger)p2.x][(NSInteger)p2.y], _board[(NSInteger)p1.x][(NSInteger)p1.y]);
	
	BOOL isLegalMove = ([p1Chain count] + [p2Chain count] > 0);
	[self _markMove:p1 to:p2 legal:isLegalMove];	
	return isLegalMove;
	
	//	return ([p1Chain count] + [p2Chain count] > 0);
}

@end
