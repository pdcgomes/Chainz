//
//  OptionsScene.m
//  Chainz
//
//  Created by Pedro Gomes on 12/14/11.
//  Copyright (c) 2011 Phluid Labs. All rights reserved.
//

#import "OptionsScene.h"

@implementation OptionsScene

#pragma mark - Class Methods

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
+ (CCScene *)scene
{
	CCScene *scene = [CCScene node];
	OptionsScene *layer = [OptionsScene node];
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

	}
	return self;
}

@end
