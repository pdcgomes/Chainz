//
//  MainMenuScene.m
//  Chainz
//
//  Created by Pedro Gomes on 12/13/11.
//  Copyright (c) 2011 Phluid Labs. All rights reserved.
//

#import "MainMenuScene.h"
#import "ClassicGameScene.h"

@implementation MainMenuScene

#pragma mark - Class Methods

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (CCScene *)scene
{
	CCScene *scene = [CCScene node];
	MainMenuScene *layer = [MainMenuScene node];
	[scene addChild:layer];

	return scene;
}

#pragma mark - Dealloc and Initialization

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)dealloc
{
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (id)init
{
	if((self = [super init])) {
		CCMenuItemLabel *classicGames	= [CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"Start Game" fontName:@"Marker Felt" fontSize:24.0] target:self selector:@selector(_startGameItemTapped)];
		CCMenuItemLabel *options		= [CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"Options" fontName:@"Marker Felt" fontSize:24.0] target:self selector:@selector(_optionsItemTapped)];
		CCMenuItemLabel *highscores		= [CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"Highscores" fontName:@"Marker Felt" fontSize:24.0] target:self selector:@selector(_highscoresItemTapped)];
		CCMenu *mainMenu				= [CCMenu menuWithItems:classicGames, options, highscores, nil];

		CGSize size = [[CCDirector sharedDirector] winSize];
		mainMenu.position		= ccp(size.width /2, size.height/2);
		classicGames.position	= ccp(0, 60);
		options.position		= ccp(0, 30);
		highscores.position		= ccp(0, 0);

		[self addChild:mainMenu];
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)_startGameItemTapped
{
	[[CCDirector sharedDirector] pushScene:[ClassicGameScene scene]];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)_optionsItemTapped
{
//	[[CCDirector sharedDirector] pushScene:[OptionsScene scene]];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)_highscoresItemTapped
{
//	[[CCDirector sharedDirector] pushScene:[HighscoreScene scene]];
}

@end
