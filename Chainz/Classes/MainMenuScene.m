//
//  MainMenuScene.m
//  Chainz
//
//  Created by Pedro Gomes on 12/13/11.
//  Copyright (c) 2011 Phluid Labs. All rights reserved.
//

#import "MainMenuScene.h"
#import "CCScene.h"

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
- (void) dealloc
{
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (id)init
{
	if((self = [super init])) {
		
		// create and initialize a Label
		CCLabelTTF *label = [CCLabelTTF labelWithString:@"Hello World" fontName:@"Marker Felt" fontSize:64];
		
		// ask director the the window size
		CGSize size = [[CCDirector sharedDirector] winSize];
		
		// position the label on the center of the screen
		label.position =  ccp( size.width /2 , size.height/2 );
		
		// add the label as a child to this Layer
		[self addChild: label];
	}
	return self;
}

@end
