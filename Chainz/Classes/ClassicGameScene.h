//
//  ClassicGameScene.h
//  Chainz
//
//  Created by Pedro Gomes on 12/13/11.
//  Copyright (c) 2011 Phluid Labs. All rights reserved.
//

#import "cocos2d.h"

@class GameBoard;

@interface ClassicGameScene : CCLayer
{
	GameBoard	*_gameboard;	
}

+ (CCScene *) scene;

@end
