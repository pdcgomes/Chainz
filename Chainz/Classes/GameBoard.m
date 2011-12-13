//
//  GameBoard.m
//  Chainz
//
//  Created by Pedro Gomes on 12/13/11.
//  Copyright (c) 2011 Phluid Labs. All rights reserved.
//

#import "GameBoard.h"
#import "Gem.h"

////////////////////////////////////////////////////////////////////////////////
// Constants and definitions
////////////////////////////////////////////////////////////////////////////////
const NSUInteger kGameboardMinSequence = 3;

////////////////////////////////////////////////////////////////////////////////
// Helper functions
////////////////////////////////////////////////////////////////////////////////
static void swap(NSInteger *a, NSInteger *b)
{
	NSInteger tmp = *a;
	*a = *b;
	*b = tmp;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface GameBoard()

- (BOOL)_isValidMove:(CGPoint)p1 p2:(CGPoint)p2;
- (NSMutableDictionary *)_findAllValidMoves;
- (NSMutableDictionary *)_findAllChains;
- (NSArray *)_findAllChainsForSequence:(NSArray *)sequence;
- (NSArray *)_floodFill:(CGPoint)node color:(NSInteger)color;

- (void)_generateAndDropDownGemsForClearedChains;
- (NSMutableArray *)_generateGemsForClearedCells;

// Used by simulateGameplay, but to be deprecated
- (NSDictionary *)_findAllSequences;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation GameBoard

#pragma mark - Dealloc and Initialization

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)dealloc
{
	[_validMoves release];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (id)init
{
	if((self = [super init])) {
		[self resetGameBoard];
	}
	return self;
}

#pragma mark - Public Methods

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)resetGameBoard
{
	unsigned int x, y;
//	for(c = 0; c < GAMEBOARD_NUM_ROWS; c++) {
//		for(r = 0; r < GAMEBOARD_NUM_COLS; r++) {
//			_board[r][c] = arc4random()%GemColorCount;
//		}
//	}

	// We need to find out if the generated board has valid chains
	// if it has, clear them, generate new gems and start over 
	// We also need to figure out if the current board is solvable
	// If not, generate a new one(?)
	BOOL boardReady = NO;
	while(!boardReady) {
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		for(y = 0; y < GAMEBOARD_NUM_ROWS; y++) {
			for(x = 0; x < GAMEBOARD_NUM_COLS; x++) {
				_board[x][y] = arc4random()%GemColorCount;
			}
		}
	
		NSMutableDictionary *chains = [self _findAllChains];
		while([chains count] > 0) {
			for(NSString *pointStr in [chains allKeys]) {
				CGPoint p = CGPointFromString(pointStr);
				NSArray *chain = [chains objectForKey:pointStr];
				[self clearChain:p sequence:chain];
			}
			[self generateGemsForClearedCells];
			
			[chains removeAllObjects];
			[chains setDictionary:[self _findAllChains]];
		}
		
		if([[self _findAllValidMoves] count] > 0) {
			boardReady = YES;
		}
		
		[pool drain];
	}
}

////////////////////////////////////////////////////////////////////////////////
// This is the actual game move, swaps a gem with another gem
// Checks if it's a valid move (did the swap result in a chain?)
// Is so, clears the resulting chain, and readjusts the board (drops gems above cleared ones)
// and also generates gems for the resulting empty cells
////////////////////////////////////////////////////////////////////////////////
- (void)swapGemAtPoint:(CGPoint)node1 withGemAtPoint:(CGPoint)node2
{
	swap(&_board[(NSInteger)node1.x][(NSInteger)node1.y], &_board[(NSInteger)node2.x][(NSInteger)node2.y]);
	// schedule the swap animation here
	
	NSArray *node1Sequences = [self _floodFill:node1 color:_board[(NSInteger)node1.x][(NSInteger)node1.y]];
	NSArray *node2Sequences = [self _floodFill:node2 color:_board[(NSInteger)node2.x][(NSInteger)node2.y]];	
	
	NSArray *node1Chain = [self _findAllChainsForSequence:node1Sequences];
	NSArray *node2Chain = [self _findAllChainsForSequence:node2Sequences];
	
	if([node1Chain count] + [node2Chain count] == 0) {
		swap(&_board[(NSInteger)node1.x][(NSInteger)node1.y], &_board[(NSInteger)node2.x][(NSInteger)node2.y]);
		// schedule the swap animation here
	}
	else {
		// schedule the swap animation here
		[self clearChain:node1 sequence:node1Chain];
		[self clearChain:node2 sequence:node2Chain];
		[self siftDownGemsAboveClearedCells];
		[self _generateAndDropDownGemsForClearedChains];
	}
}


////////////////////////////////////////////////////////////////////////////////
// Iterates the whole board and generates new gems for all cells marked as cleared (-1)
// Schedules the drop down animation of all generated gems
////////////////////////////////////////////////////////////////////////////////
- (void)_generateAndDropDownGemsForClearedChains
{
	NSMutableArray *generatedGems = [self _generateGemsForClearedCells];
	for(NSString *pointStr in generatedGems) {
		// Create the actual gem sprite, add it outside the gameboard and schedule
		// a drop animation action to the destination point
	}
}

////////////////////////////////////////////////////////////////////////////////
// Iterates the whole board and generates new gems for all cells marked as cleared (-1)
// Returns the list of all positions where new gems have been generated
////////////////////////////////////////////////////////////////////////////////
- (NSMutableArray *)_generateGemsForClearedCells
{
	NSMutableArray *generatedGems = [[NSMutableArray alloc] init];
	
	NSInteger x, y;
	for(x = GAMEBOARD_NUM_COLS-1; x >= 0; x--) {
		for(y = GAMEBOARD_NUM_ROWS; y >= 0; y--) {
			if(_board[x][y] == -1) {
				_board[x][y] = arc4random()%GemColorCount;
				[generatedGems addObject:NSStringFromCGPoint((CGPoint){x,y})];
			}
		}
	}
	return [generatedGems autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// Clears (marks) all gems in a given chain
////////////////////////////////////////////////////////////////////////////////
- (void)clearChain:(CGPoint)point sequence:(NSArray *)sequence
{
	//	NSInteger x, y;
	for(NSString *pointStr in sequence) {
		CGPoint p = CGPointFromString(pointStr);
		_board[(NSInteger)p.x][(NSInteger)p.y] = -1;
	}
	// schedule the clear animation
}

////////////////////////////////////////////////////////////////////////////////
// Iterates over the whole board and generates a random gem for every position
// TODO: add some way to be able to tweak the generation process (like a bias factor or something)
// This way we could generate board with higher/lower number of possible matches
////////////////////////////////////////////////////////////////////////////////
- (void)generateGemsForClearedCells
{
	NSInteger x, y;
	for(x = 0; x < GAMEBOARD_NUM_ROWS; x++) {
		for(y = 0; y < GAMEBOARD_NUM_COLS; y++) {
			if(_board[x][y] == -1) {
				_board[x][y] = arc4random()%GemColorCount;
			}
		}
	}
}

////////////////////////////////////////////////////////////////////////////////
// Shifts down all gems that are above cleared chains
// Also schedules the drop down animation
// NOTE: should we just returns the list of position updates so we can deliver them to an animator later?
////////////////////////////////////////////////////////////////////////////////
- (void)siftDownGemsAboveClearedCells
{
	NSInteger x, y;
	[self printBoard];
	for(x = GAMEBOARD_NUM_COLS-1; x >= 0; x--) {
		for(y = GAMEBOARD_NUM_ROWS-1; y >= 0; y--) {
			if(_board[x][y] != -1) continue;
			NSInteger py = y-1;
			while(py >= 0 && _board[x][py] == -1) {
				py--;
			}
			if(py >= 0) {
				_board[x][y] = _board[x][py];
				_board[x][py] = -1;
				// schedule the drop down animation here
				// or
				// save the position update (src => destination) and return the list
			}
		}
	}
	// schedule the drop animations for every gem we actually moved down
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)simulateGameplay
{
	[self resetGameBoard];
	
	//	printMatrix(NUM_ROWS, NUM_COLS, matrix);
	//	swapGems(NSMakePoint(0, 0), NSMakePoint(1, 0));
	//	printMatrix(NUM_ROWS, NUM_COLS, matrix);
	
	NSDictionary *matches = [self _findAllSequences];
	int move = 1;
	while([matches count] > 0) {
		NSArray *positions = [matches allKeys];
		NSInteger pos = arc4random()%[positions count];
		NSString *key = [positions objectAtIndex:pos];
		NSLog(@"pos = %@", key);
		NSLog(@"move %d", move++);
		
		
		NSArray *chains = [self _findAllChainsForSequence:[matches objectForKey:key]];
		[self clearChain:CGPointFromString(key) sequence:chains];
		[self siftDownGemsAboveClearedCells];
		[self printBoard];
		[self generateGemsForClearedCells];
		[self printBoard];
		matches = [self _findAllSequences];
	}
	
	NSLog(@"No more moves left!");	
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)printBoard
{
	unsigned int x, y;
	
	NSMutableString	*matrixStr = [[NSMutableString alloc] initWithString:@"\n"];
	for(y = 0; y < GAMEBOARD_NUM_COLS; y++) {
		for(x = 0; x < GAMEBOARD_NUM_ROWS; x++) {
			[matrixStr appendFormat:@"[%2d] ", _board[x][y]];
		}
		[matrixStr appendString:@"\n"];
	}
	
	NSLog(@"%@", matrixStr);
	[matrixStr release];
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
////////////////////////////////////////////////////////////////////////////////
- (NSArray *)_findAllChainsForSequence:(NSArray *)sequence
{
	NSLog(@"***** FINDING ALL VALID CHAINS *****");
	NSLog(@"sequence = %@", sequence);
	
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
	
	NSArray *sortedByRows = [sequence sortedArrayUsingComparator:(NSComparator)^(id obj1, id obj2) {
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
	
	NSLog(@"chain = %@", chain);
	
	return [chain autorelease];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSDictionary *)_findAllSequences
{
	[self printBoard];
	
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

////////////////////////////////////////////////////////////////////////////////
// Inspects the whole board and returns a list of all current chains 
// [source_point] => [list of points that comprise the chain]
////////////////////////////////////////////////////////////////////////////////
- (NSMutableDictionary *)_findAllChains
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
////////////////////////////////////////////////////////////////////////////////
- (NSDictionary *)_findAllValidMoves
{
	NSMutableDictionary *moves = [[NSMutableDictionary alloc] init];
	
	NSUInteger x, y;
	for(x = 0; x < GAMEBOARD_NUM_COLS; x++) {
		for(y = 0; y < GAMEBOARD_NUM_ROWS; y++) {
			NSMutableArray *movesForPoint = [[NSMutableArray alloc] initWithCapacity:4];
			CGPoint p = (CGPoint){x, y};
			if([self _isValidMove:p p2:(CGPoint){x+1, y}]) {
				[movesForPoint addObject:NSStringFromCGPoint((CGPoint){x+1, y})];
			}
			if([self _isValidMove:p p2:(CGPoint){x-1, y}]) {
				[movesForPoint addObject:NSStringFromCGPoint((CGPoint){x-1, y})];
			}
			if([self _isValidMove:p p2:(CGPoint){x, y+1}]) {
				[movesForPoint addObject:NSStringFromCGPoint((CGPoint){x, y+1})];
			}
			if([self _isValidMove:p p2:(CGPoint){x, y-1}]) {
				[movesForPoint addObject:NSStringFromCGPoint((CGPoint){x, y-1})];
			}
			if([movesForPoint count] > 0) {
				[moves setObject:movesForPoint forKey:NSStringFromCGPoint(p)];
			}
			[movesForPoint release];
		}
	}
	return [moves autorelease];
}

////////////////////////////////////////////////////////////////////////////////
// Checks whether performing a p1 <-> p2 swap would result in a valid move
////////////////////////////////////////////////////////////////////////////////
- (BOOL)_isValidMove:(CGPoint)p1 p2:(CGPoint)p2
{
	CGRect bounds = CGRectMake(0, 0, GAMEBOARD_NUM_COLS, GAMEBOARD_NUM_ROWS);
	BOOL gameboardContainsPoints = CGRectContainsPoint(bounds, p1) && CGRectContainsPoint(bounds, p2);
	if(!gameboardContainsPoints) {
		return NO;
	}
	swap(&_board[(NSInteger)p1.x][(NSInteger)p1.y], &_board[(NSInteger)p2.x][(NSInteger)p2.y]);
	
	NSArray *p1Sequences = [self _floodFill:p1 color:_board[(NSInteger)p1.x][(NSInteger)p1.y]];
	NSArray *p2Sequences = [self _floodFill:p2 color:_board[(NSInteger)p2.x][(NSInteger)p2.y]];	
	
	NSArray *p1Chain = [self _findAllChainsForSequence:p1Sequences];
	NSArray *p2Chain = [self _findAllChainsForSequence:p2Sequences];

	swap(&_board[(NSInteger)p2.x][(NSInteger)p2.y], &_board[(NSInteger)p1.x][(NSInteger)p1.y]);
	
	return ([p1Chain count] + [p2Chain count] > 0);
}

@end
