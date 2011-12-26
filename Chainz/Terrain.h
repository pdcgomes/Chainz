//
//  Terrain.h
//  TinySeal
//
//  Created by Ray Wenderlich on 6/15/11.
//  Copyright 2011 Ray Wenderlich. All rights reserved.
//

#import "cocos2d.h"

@class HelloWorldLayer;

#define kMaxTerrainKeyPoints 	1000
#define kTerrainSegmentWidth 	5
#define kMaxTerrainVertices 	4000
#define kMaxBorderVertices 		800 

@interface Terrain : CCNode
{
    int 		_offsetX;
    CCSprite 	*_stripes;

	CGPoint 	_terrainKeyPoints[kMaxTerrainKeyPoints];
    int 		_drawFromKeyPoint;
    int 		_drawToKeyPoint;

    CGPoint 	_terrainVertices[kMaxTerrainVertices];
    CGPoint 	_terrainTexCoords[kMaxTerrainVertices];
    CGPoint 	_borderVertices[kMaxBorderVertices];
	
	int 		_numTerrainVertices;
	int 		_numBorderVertices;
}

@property (retain) CCSprite *stripes;

- (void)setOffsetX:(float)offset;

@end
