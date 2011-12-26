//
//  Terrain.m
//  TinySeal
//
//  Created by Ray Wenderlich on 6/15/11.
//  Copyright 2011 Ray Wenderlich. All rights reserved.
//

#import "Terrain.h"
//#import "HelloWorldLayer.h"

@interface Terrain()

- (void)_generateTerrain;
- (void)_resetTerrainVertices;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation Terrain

@synthesize stripes = _stripes;


#pragma mark - Dealloc and Initialization

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)dealloc
{
    [_stripes release];
    _stripes = nil;
    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (id)init
{
    if ((self = [super init])) {
        [self _generateTerrain];
        [self _resetTerrainVertices];
    }
    return self;
}

#pragma mark - Public Methods

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)setOffsetX:(float)newOffsetX
{
    _offsetX = newOffsetX;
    self.position = CGPointMake(-_offsetX * self.scale, 0);
    [self _resetTerrainVertices];
}

#pragma mark - CCNode

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)draw 
{
    glBindTexture(GL_TEXTURE_2D, _stripes.texture.name);
    glDisableClientState(GL_COLOR_ARRAY);
    
    glColor4f(1, 1, 1, 1);
    glVertexPointer(2, GL_FLOAT, 0, _terrainVertices);
    glTexCoordPointer(2, GL_FLOAT, 0, _terrainTexCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)_numTerrainVertices);
    
    /*for(int i = MAX(_fromKeyPointI, 1); i <= _toKeyPointI; ++i) {
	 glColor4f(1.0, 0, 0, 1.0); 
	 ccDrawLine(_hillKeyPoints[i-1], _hillKeyPoints[i]);     
	 
	 glColor4f(1.0, 1.0, 1.0, 1.0);
	 
	 CGPoint p0 = _hillKeyPoints[i-1];
	 CGPoint p1 = _hillKeyPoints[i];
	 int hSegments = floorf((p1.x-p0.x)/kHillSegmentWidth);
	 float dx = (p1.x - p0.x) / hSegments;
	 float da = M_PI / hSegments;
	 float ymid = (p0.y + p1.y) / 2;
	 float ampl = (p0.y - p1.y) / 2;
	 
	 CGPoint pt0, pt1;
	 pt0 = p0;
	 for (int j = 0; j < hSegments+1; ++j) {
	 
	 pt1.x = p0.x + j*dx;
	 pt1.y = ymid + ampl * cosf(da*j);
	 
	 ccDrawLine(pt0, pt1);
	 
	 pt0 = pt1;
	 
	 }
	 }*/
}

#pragma mark - Private Methods

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)_generateTerrain 
{
    CGSize winSize = [CCDirector sharedDirector].winSize;
    
    float minDX = 160;
    float minDY = 60;
    int rangeDX = 80;
    int rangeDY = 40;
    
    float x = -minDX;
    float y = winSize.height / 2-minDY;
    
    float dy, ny;
    float sign = 1; // +1 - going up, -1 - going  down
    float paddingTop = 20;
    float paddingBottom = 20;
    
    for(int i = 0; i < kMaxTerrainKeyPoints; i++) {
        _terrainKeyPoints[i] = CGPointMake(x, y);
		if(i > 0) {
            x += rand()%rangeDX+minDX;
            while(true) {
                dy = rand()%rangeDY+minDY;
                ny = y + dy*sign;
                if(ny < winSize.height-paddingTop && ny > paddingBottom) {
                    break;   
                }
            }
            y = ny;
		}
		else {
            x = 0;
            y = winSize.height/2;
		}
		
        sign *= -1;
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)_resetTerrainVertices
{
    CGSize winSize = [CCDirector sharedDirector].winSize;
    
    static int prevDrawFromKeyPoint = -1;
    static int prevDrawToKeyPoint = -1;
    
    // key points interval for drawing
    while(_terrainKeyPoints[_drawFromKeyPoint+1].x < _offsetX-winSize.width/8/self.scale) {
        _drawFromKeyPoint++;
    }
    while(_terrainKeyPoints[_drawToKeyPoint].x < _offsetX+winSize.width*9/8/self.scale) {
        _drawToKeyPoint++;
    }
    
	BOOL keyPointsHaveChanged = (prevDrawFromKeyPoint != _drawFromKeyPoint || 
								 prevDrawToKeyPoint   != _drawToKeyPoint);
	if(!keyPointsHaveChanged) {
		return;
	}
	
	// vertices for visible area
	_numTerrainVertices = 0;
	_numBorderVertices = 0;
	CGPoint p0, p1, pt0, pt1;
	p0 = _terrainKeyPoints[_drawFromKeyPoint];
	for(int i = _drawFromKeyPoint + 1; i<_drawToKeyPoint + 1; i++) {
		p1 = _terrainKeyPoints[i];
		
		// triangle strip between p0 and p1
		int horizontalSegments = floorf((p1.x-p0.x) / kTerrainSegmentWidth);
		float dx = (p1.x - p0.x) / horizontalSegments;
		float da = M_PI / horizontalSegments;
		float ymid = (p0.y + p1.y) / 2;
		float ampl = (p0.y - p1.y) / 2;
		pt0 = p0;
		_borderVertices[_numBorderVertices++] = pt0;
		for(int j = 1; j < horizontalSegments + 1; j++) {
			pt1.x = p0.x + j*dx;
			pt1.y = ymid + ampl * cosf(da*j);
			_borderVertices[_numBorderVertices++] = pt1;
			
			_terrainVertices[_numTerrainVertices] = CGPointMake(pt0.x, 0);
			_terrainTexCoords[_numTerrainVertices++] = CGPointMake(pt0.x/512, 1.0f);
			_terrainVertices[_numTerrainVertices] = CGPointMake(pt1.x, 0);
			_terrainTexCoords[_numTerrainVertices++] = CGPointMake(pt1.x/512, 1.0f);
			
			_terrainVertices[_numTerrainVertices] = CGPointMake(pt0.x, pt0.y);
			_terrainTexCoords[_numTerrainVertices++] = CGPointMake(pt0.x/512, 0);
			_terrainVertices[_numTerrainVertices] = CGPointMake(pt1.x, pt1.y);
			_terrainTexCoords[_numTerrainVertices++] = CGPointMake(pt1.x/512, 0);
			
			pt0 = pt1;
		}
		
		p0 = p1;
	}
	
	prevDrawFromKeyPoint = _drawFromKeyPoint;
	prevDrawToKeyPoint = _drawToKeyPoint;        
}

@end
