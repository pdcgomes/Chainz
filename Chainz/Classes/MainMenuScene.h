//
//  MainMenuScene.h
//  Chainz
//
//  Created by Pedro Gomes on 12/13/11.
//  Copyright (c) 2011 Phluid Labs. All rights reserved.
//

#import "cocos2d.h"

@class Terrain;
@interface MainMenuScene : CCLayer
{
	CCSprite	*_backgroundGradientSprite;
	CCSprite	*_backgroundSprite;
	Terrain		*_terrain;
}

+ (CCScene *) scene;

@end
