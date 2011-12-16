//
//  ClassicGameScene.m
//  Chainz
//
//  Created by Pedro Gomes on 12/13/11.
//  Copyright (c) 2011 Phluid Labs. All rights reserved.
//

#import "ClassicGameScene.h"
#import "GameBoard.h"

@implementation ClassicGameScene

#pragma mark - Class Methods

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (CCScene *)scene
{
	CCScene *scene = [CCScene node];
	ClassicGameScene *layer = [ClassicGameScene node];
	[scene addChild:layer];
	
	return scene;
}

#pragma mark - Dealloc and Initialization

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void) dealloc
{
	[_gameboard release];
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (id)init
{
	if((self = [super init])) {
		_gameboard = [[GameBoard alloc] init];
		[_gameboard setContentSize:[[CCDirector sharedDirector] winSize]];
		[_gameboard resetGameBoard];
		[self addChild:_gameboard];
		[_gameboard setIsTouchEnabled:YES];
	}
	return self;
}

@end
