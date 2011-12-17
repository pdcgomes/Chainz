//
//  GameBoard.m
//  Chainz
//
//  Created by Pedro Gomes on 12/13/11.
//  Copyright (c) 2011 Phluid Labs. All rights reserved.
//

#import "GameBoard.h"
#import "Gem.h"
#import "CCDrawingPrimitives.h"

////////////////////////////////////////////////////////////////////////////////
// Constants and definitions
////////////////////////////////////////////////////////////////////////////////
const NSUInteger 	kGameboardMinSequence 	= 3;

const NSInteger 	kGameboardNumberOfRows	= 8;
const NSInteger 	kGameboardNumberOfCols	= 8;
const CGSize		kGameboardCellSize		= {40.0, 40.0};

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
static NSInteger GemIndexForBoardPosition(CGPoint p) 
{
	return p.x*GAMEBOARD_NUM_COLS + p.y;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
#define GEM_SPACING 40.0
static CGPoint CoordinatesForGemAtPosition(CGPoint p) 
{
//	CGSize windowSize = [[CCDirector sharedDirector] winSize];
//	CGFloat yOrigin = (windowSize.height - windowSize.width)-GEM_SPACING;
	CGFloat x = p.x*GEM_SPACING+1 + 12;
	CGFloat y = GEM_SPACING*(GAMEBOARD_NUM_ROWS-1) - p.y*GEM_SPACING + 12;
	return CGPointMake(x, y);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
static CGPoint CoordinatesForWindowLocation(CGPoint p)
{
	CGSize windowSize = [[CCDirector sharedDirector] winSize];
	CGRect rect = CGRectMake(0, 0, windowSize.width, windowSize.width);
	if(!CGRectContainsPoint(rect, p)) {
		return (CGPoint){NSNotFound, NSNotFound};
	}

	CGFloat x = GAMEBOARD_NUM_COLS - floor((rect.size.width - p.x)/GEM_SPACING) - 1;
	CGFloat y = floor((rect.size.height - p.y)/GEM_SPACING);
	
	return (CGPoint){x, y};
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface GameBoard()

- (void)_updateAllValidMoves;
- (BOOL)_isValidMove:(CGPoint)p1 p2:(CGPoint)p2;
- (NSMutableDictionary *)_findAllValidMoves;

- (NSArray *)_floodFill:(CGPoint)node color:(NSInteger)color;
- (NSArray *)_findAllChainsForSequence:(NSArray *)sequence;
- (NSArray *)_findAllChainsFromPoint:(CGPoint)point;
- (NSMutableDictionary *)_findAllChains;

- (void)_dropDanglingGems;
- (void)_generateAndDropDownGemsForClearedChains;
- (NSMutableArray *)_generateGemsForClearedCells;

// Used by simulateGameplay, but to be deprecated
- (NSDictionary *)_findAllSequences;

- (void)_drawGameboardGrid;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation GameBoard

#pragma mark - Dealloc and Initialization

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)dealloc
{
	[_validMovesLookupTable release];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (id)init
{
	if((self = [super init])) {
//		[self resetGameBoard];
//		self.isTouchEnabled = YES;
	}
	return self;
}

#pragma mark - CCNode

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)draw
{
	[super draw];
	[self _drawGameboardGrid];
}

////////////////////////////////////////////////////////////////////////////////
// Just a helper grid
////////////////////////////////////////////////////////////////////////////////
- (void)_drawGameboardGrid
{
	CGSize windowSize = [[CCDirector sharedDirector] winSize];
	
	CGPoint borderVertices[4] = {{1,1}, {windowSize.width-1, 1}, {windowSize.width-1, windowSize.height-1}, {1, windowSize.height-1}};
	ccDrawPoly(borderVertices, 4, YES);
	
	CGFloat gridHeight = windowSize.height - (windowSize.width/2.0);
	CGFloat gridSpacing = 40.0;
	NSInteger x, y;
	for(x = 1; x < GAMEBOARD_NUM_COLS; x++) {
		ccDrawLine((CGPoint){x*gridSpacing, 0}, (CGPoint){x*gridSpacing, gridHeight});
	}
	for(y = 1; y <= GAMEBOARD_NUM_ROWS; y++) {
		ccDrawLine((CGPoint){0, (y*gridSpacing)}, (CGPoint){windowSize.width, (y*gridSpacing)});
	}
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
		
		for(x = 0; x < GAMEBOARD_NUM_COLS; x++) {
			for(y = 0; y < GAMEBOARD_NUM_ROWS; y++) {
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
	[self printBoard];
	
	if(!_gems) {
		_gems = [[NSMutableArray alloc] initWithCapacity:GAMEBOARD_NUM_ROWS*GAMEBOARD_NUM_COLS];
	}
	
	for(x = 0; x < GAMEBOARD_NUM_COLS; x++) {
		for(y = 0; y < GAMEBOARD_NUM_ROWS; y++) {
			Gem *gem = [[Gem alloc] initWithGameboard:self position:(CGPoint){x,y} kind:GemKindNormal color:_board[x][y]];
//			gem.anchorPoint = CGPointZero;
			gem.position = CoordinatesForGemAtPosition((CGPoint){x,y});
			
//			CCLOG(@"%@ = %@, c = %d", NSStringFromCGPoint(gem.point), NSStringFromCGPoint(gem.position), gem.gemColor);
			[self addChild:gem];
			[_gems addObject:gem];
			[gem release];
		}
	}
}

////////////////////////////////////////////////////////////////////////////////
// This is the actual game move, swaps a gem with another gem
// Checks if it's a valid move (did the swap result in a chain?)
// Is so, clears the resulting chain, and readjusts the board (drops gems above cleared ones)
// and also generates gems for the resulting empty cells
////////////////////////////////////////////////////////////////////////////////
- (void)swapGemAtPoint:(CGPoint)point1 withGemAtPoint:(CGPoint)point2
{
	// TODO: lookup _validMovesLookupTable, if it's not a valid movement 
	// we simply schedule two animations (swap node1 <-> node2, swap node2 <-> node1)
	// else, compute the actual chains, clear them, etc.

//	swap(&_board[(NSInteger)node1.x][(NSInteger)node1.y], &_board[(NSInteger)node2.x][(NSInteger)node2.y]);
	CC_SWAP(_board[(NSInteger)point1.x][(NSInteger)point1.y], _board[(NSInteger)point2.x][(NSInteger)point2.y]);
	// schedule the swap animation here
//	[_gems exchangeObjectAtIndex:GemIndexForBoardPosition(node1) withObjectAtIndex:GemIndexForBoardPosition(node2)];
	
	NSInteger indexGem1 = GemIndexForBoardPosition(point1);
	NSInteger indexGem2 = GemIndexForBoardPosition(point2);
	
	Gem *gem1 = [_gems objectAtIndex:indexGem1];
	Gem *gem2 = [_gems objectAtIndex:indexGem2];
	[_gems exchangeObjectAtIndex:indexGem1 withObjectAtIndex:indexGem2];
    CC_SWAP(gem1.point, gem2.point);

//	NSArray *node1Sequences = [self _floodFill:node1 color:_board[(NSInteger)node1.x][(NSInteger)node1.y]];
//	NSArray *node2Sequences = [self _floodFill:node2 color:_board[(NSInteger)node2.x][(NSInteger)node2.y]];	
//	
//	NSArray *node1Chain = [self _findAllChainsForSequence:node1Sequences];
//	NSArray *node2Chain = [self _findAllChainsForSequence:node2Sequences];
	
	NSArray *point1Chain = [self _findAllChainsFromPoint:point1];
	NSArray *point2Chain = [self _findAllChainsFromPoint:point2];

	id swapGem1Action = [CCMoveTo actionWithDuration:0.4 position:gem2.position];
	id swapGem2Action = [CCMoveTo actionWithDuration:0.4 position:gem1.position];
	
	if([point1Chain count] + [point2Chain count] == 0) {
		id swapGem1ReverseAction = [CCMoveTo actionWithDuration:0.4 position:gem1.position];
		id swapGem2ReverseAction = [CCMoveTo actionWithDuration:0.4 position:gem2.position];

		CC_SWAP(_board[(NSInteger)point1.x][(NSInteger)point1.y], _board[(NSInteger)point2.x][(NSInteger)point2.y]);
        CC_SWAP(gem1.point, gem2.point);
		[_gems exchangeObjectAtIndex:indexGem1 withObjectAtIndex:indexGem2];
		
		id gem1Sequence = [CCSequence actions:swapGem1Action, swapGem1ReverseAction, nil];
		id gem2Sequence = [CCSequence actions:swapGem2Action, swapGem2ReverseAction, nil];
		
		[gem1 runAction:gem1Sequence];
		[gem2 runAction:gem2Sequence];
	}
	else {
		[gem1 runAction:swapGem1Action];
		[gem2 runAction:swapGem2Action];

		double delayInSeconds = 0.41;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
			[self clearChain:point1 sequence:point1Chain];
			[self clearChain:point2 sequence:point2Chain];
			[self _dropDanglingGems];
			[self _generateAndDropDownGemsForClearedChains];
			
//			BOOL done = NO;
//			while(!done) {
//				NSDictionary *comboChains = [self _findAllChains];
//				if([comboChains count] == 0) break;
//				
//				for(NSString *pointStr in [comboChains allKeys]) {
//					[self clearChain:CGPointFromString(pointStr) sequence:[comboChains objectForKey:pointStr]];
//				}
//				[self _dropDanglingGems];
//			}
//			[self _generateAndDropDownGemsForClearedChains];
		});
	}
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)moveGemAtPoint:(CGPoint)point withDirection:(GameboardMovementDirection)direction
{
	CGPoint destPoint = point;
	switch(direction)
	{
		case GameboardMovementDirectionUp:
			if(point.y - 1 >= 0) destPoint = CGPointMake(point.x, point.y-1);
			break;
			
		case GameboardMovementDirectionDown:
			if(point.y + 1 < GAMEBOARD_NUM_ROWS) destPoint = CGPointMake(point.x, point.y+1);
			break;
			
		case GameboardMovementDirectionLeft:
			if(point.x - 1 >= 0) destPoint = CGPointMake(point.x - 1, point.y);
			break;
			
		case GameboardMovementDirectionRight:
			if(point.x + 1 < GAMEBOARD_NUM_COLS) destPoint = CGPointMake(point.x + 1, point.y);
			break;

		default: break;
	}
	
	if(CGPointEqualToPoint(point, destPoint)) {
		return NO;
	}

	[self swapGemAtPoint:point withGemAtPoint:destPoint];
	return YES;
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
		CGPoint boardPos = CGPointFromString(pointStr);
		Gem *gem = [[Gem alloc] initWithGameboard:self position:boardPos kind:GemKindNormal color:_board[(NSInteger)boardPos.x][(NSInteger)boardPos.y]];
		CGPoint dstSpritePosition = CoordinatesForGemAtPosition(gem.point);
		CGPoint srcSpritePosition = {dstSpritePosition.x, kGameboardNumberOfRows*kGameboardCellSize.height+kGameboardCellSize.height};
		gem.position = srcSpritePosition;
		
		[self addChild:gem];
		[gem runAction:[CCMoveTo actionWithDuration:0.4 position:dstSpritePosition]];
		
		[_gems replaceObjectAtIndex:GemIndexForBoardPosition(boardPos) withObject:gem];
		[gem release];
	}
	[self printBoard];
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
		
		NSInteger gemIndex = GemIndexForBoardPosition(p);
		Gem *gem = [_gems objectAtIndex:gemIndex];
		[gem removeFromParentAndCleanup:YES];
		[_gems replaceObjectAtIndex:gemIndex withObject:[NSNull null]];
	}
	[self visit];
	// schedule the clear animation
}

////////////////////////////////////////////////////////////////////////////////
// Iterates over the whole board and generates a random gem for every position
// TODO: figure out a way to be able to tweak the generation process (like a bias factor or something)
// This way we could generate boards with higher/lower number of possible matches
////////////////////////////////////////////////////////////////////////////////
- (void)generateGemsForClearedCells
{
	NSInteger x, y;
	for(x = 0; x < GAMEBOARD_NUM_COLS; x++) {
		for(y = 0; y < GAMEBOARD_NUM_ROWS; y++) {
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
- (void)_dropDanglingGems
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
				CGPoint oldPos = {x, py};
				CGPoint newPos = {x, y};
				
				NSInteger oldIndex = GemIndexForBoardPosition(oldPos);
				NSInteger newIndex = GemIndexForBoardPosition(newPos);
				
				[_gems exchangeObjectAtIndex:oldIndex withObjectAtIndex:newIndex];
				id gem = [_gems objectAtIndex:newIndex];
				if([gem isKindOfClass:[Gem class]]) {
					[(Gem *)gem setPoint:newPos];
					CCMoveBy *action = [CCMoveTo actionWithDuration:0.3 position:CoordinatesForGemAtPosition(newPos)];
					[(Gem *)gem runAction:action];
				}
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
		[self _dropDanglingGems];
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
//	NSLog(@"***** FINDING ALL VALID CHAINS *****");
//	NSLog(@"sequence = %@", sequence);
	
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
	
//	NSLog(@"chain = %@", chain);
	
	return [chain autorelease];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (NSArray *)_findAllChainsFromPoint:(CGPoint)point
{
	NSArray *sequences = [self _floodFill:point color:_board[(NSInteger)point.x][(NSInteger)point.y]];
	return [self _findAllChainsForSequence:sequences];
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
// NOTE: consider turning this in an updateAllValidMoves method and cache the results
// any subsequent movement attempt would only require a dictionary lookup
// after all chains are processed, we would invoke this method agan to recompute
// all valid moves - this would also make the job of handing tips to the user a lot easier
////////////////////////////////////////////////////////////////////////////////
- (NSDictionary *)_findAllValidMoves
{
	[self _updateAllValidMoves];
	return _validMovesLookupTable;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)_updateAllValidMoves
{
	if(!_validMovesLookupTable) {
		_validMovesLookupTable = [[NSMutableDictionary alloc] init];
	}
	[_validMovesLookupTable removeAllObjects];
	
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
				[_validMovesLookupTable setObject:movesForPoint forKey:NSStringFromCGPoint(p)];
			}
			[movesForPoint release];
		}
	}
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
//	swap(&_board[(NSInteger)p1.x][(NSInteger)p1.y], &_board[(NSInteger)p2.x][(NSInteger)p2.y]);
	CC_SWAP(_board[(NSInteger)p1.x][(NSInteger)p1.y], _board[(NSInteger)p2.x][(NSInteger)p2.y]);
	
	NSArray *p1Sequences = [self _floodFill:p1 color:_board[(NSInteger)p1.x][(NSInteger)p1.y]];
	NSArray *p2Sequences = [self _floodFill:p2 color:_board[(NSInteger)p2.x][(NSInteger)p2.y]];	
	
	NSArray *p1Chain = [self _findAllChainsForSequence:p1Sequences];
	NSArray *p2Chain = [self _findAllChainsForSequence:p2Sequences];

//	swap(&_board[(NSInteger)p2.x][(NSInteger)p2.y], &_board[(NSInteger)p1.x][(NSInteger)p1.y]);
	CC_SWAP(_board[(NSInteger)p2.x][(NSInteger)p2.y], _board[(NSInteger)p1.x][(NSInteger)p1.y]);
	
	return ([p1Chain count] + [p2Chain count] > 0);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
//{
//	CGPoint p = CoordinatesForWindowLocation([touch locationInView:touch.window]);
//	if(CGPointEqualToPoint(p, CGPointMake(NSNotFound, NSNotFound))) {
//		return NO;
//	}
//
//	CGPoint touchLocation = [touch locationInView:touch.window];
//	CGPoint touchLocationFlipped = {touchLocation.x, [[CCDirector sharedDirector] winSize].height - touchLocation.y};
//	
//
//	return YES;
//	
//	CGRect spriteRect = (CGRect){self.position, rect_.size};
//	
//	if(CGRectContainsPoint(spriteRect, touchPointFlipped)) {
//		CCLOG(@"Touched gem %@", NSStringFromCGPoint(self.point));
//		_firstTouchLocation = touchPointFlipped;
//		return YES;
//	}
//	return NO;
//	
//	CCLOG(@"Gameboard touch location = %@, sprite_frame = %@", NSStringFromCGPoint(touchPoint), NSStringFromCGRect((CGRect){self.position, rect_.size}));
//	//	CCLOG(@"Gameboard gem index = %@", NSStringFromCGPoint(CoordinatesForWindowLocation(p)));
//	return YES;
//}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
//{
//	_moved = YES;
//}

//////////////////////////////////////////////////////////////////////////////////
// Note: consider moving the gem touch handling logic to the gameboard itself
// besided the potential improvement in performance (individual gems don't have to handle touches)
// it's probably a much more flexible design
//////////////////////////////////////////////////////////////////////////////////
//- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
//{
//	if(!_moved) {
//		[self markSelected:YES];
//	}
//	else {
//		CGPoint endTouchLocation = [touch locationInView:touch.window];
//		CGPoint endTouchLocationFlipped = {endTouchLocation.x, [[CCDirector sharedDirector] winSize].height - endTouchLocation.y};
//		
//		// vertical or horizontal?
//		CGFloat horizontalOffset = endTouchLocationFlipped.x - _firstTouchLocation.x;
//		CGFloat verticalOffset = endTouchLocationFlipped.y - _firstTouchLocation.y;
//		
//		if(fabs(horizontalOffset) >= fabs(verticalOffset)) { // moved horizontally
//			if(horizontalOffset > 0) {
//				[_gameboard moveGemAtPoint:self.point withDirection:GameboardMovementDirectionRight];
//			}
//			else if(horizontalOffset < 0) {
//				[_gameboard moveGemAtPoint:self.point withDirection:GameboardMovementDirectionLeft];
//			}
//		}
//		else {
//			if(horizontalOffset > 0) {
//				[_gameboard moveGemAtPoint:self.point withDirection:GameboardMovementDirectionUp];
//			}
//			else if(horizontalOffset < 0) {
//				[_gameboard moveGemAtPoint:self.point withDirection:GameboardMovementDirectionDown];
//			}
//		}
//	}
//	
//	_firstTouchLocation = CGPointZero;
//}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//- (void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
//{
//	_firstTouchLocation = CGPointZero;
//}

@end
