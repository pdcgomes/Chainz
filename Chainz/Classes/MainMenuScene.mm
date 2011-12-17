//
//  MainMenuScene.m
//  Chainz
//
//  Created by Pedro Gomes on 12/13/11.
//  Copyright (c) 2011 Phluid Labs. All rights reserved.
//

#import "MainMenuScene.h"
#import "ClassicGameScene.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@interface MainMenuScene()

- (void)_generateBackground;
- (ccColor4F)_randomBrightColor;
- (CCSprite *)_backgroundSpriteWithColor1:(ccColor4F)color1 color2:(ccColor4F)color2 textureSize:(float)textureSize cols:(int)numCols rows:(int)numRows;

@end

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
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
		[self _generateBackground];

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
		[self scheduleUpdate];
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

#pragma mark - Private Methods

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)_generateBackground
{
	ccColor4F color1 = [self _randomBrightColor];
	ccColor4F color2 = [self _randomBrightColor];

	_backgroundSprite = [self _backgroundSpriteWithColor1:color1 color2:color2 textureSize:512 cols:8 rows:8];
	
	CGSize windowSize = [[CCDirector sharedDirector] winSize];
	_backgroundSprite.position = ccp(windowSize.width/2, windowSize.height/2);
	ccTexParams textureParams = { GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_REPEAT };
	[_backgroundSprite.texture setTexParameters:&textureParams];
	
	[self addChild:_backgroundSprite];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (CCSprite *)_backgroundSpriteWithColor1:(ccColor4F)color1 color2:(ccColor4F)color2 textureSize:(float)textureSize cols:(int)numCols rows:(int)numRows
{
	CCRenderTexture *textureRenderer = [CCRenderTexture renderTextureWithWidth:textureSize height:textureSize];
	[textureRenderer beginWithClear:color1.r g:color1.g b:color1.b a:1];
	
	glDisable(GL_TEXTURE_2D);
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);
	
	// Render horizontal stripes
	CGPoint vertices[numRows * 6];
	float x1 = -textureSize;
	float x2;
	float y1 = textureSize;
	float y2 = 0;
	float dx = textureSize / numRows * 2;
    float stripeWidth = dx/2;
	
	int numVertices = 0;
    for(int i = 0; i < numRows; i++) {
        x2 = x1 + textureSize;
        vertices[numVertices++] = CGPointMake(x1, y1);
        vertices[numVertices++] = CGPointMake(x1+stripeWidth, y1);
        vertices[numVertices++] = CGPointMake(x2, y2);
		vertices[numVertices++] = vertices[numVertices-2];
        vertices[numVertices++] = CGPointMake(x2+stripeWidth, y2);
        vertices[numVertices++] = vertices[numVertices-5];
        x1 += dx;
    }
    
    glColor4f(color2.r, color2.g, color2.b, color2.a);
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glDrawArrays(GL_TRIANGLES, 0, (GLsizei)numVertices);
	
	// Render vertical stripes
	
	// Render gradient here
	glEnableClientState(GL_COLOR_ARRAY);
	
	float gradientAlpha = 0.7;
	ccColor4F colors[4];
	numVertices = 0;
	
	vertices[numVertices] = CGPointMake(0, 0);
	colors[numVertices++] = (ccColor4F){0, 0, 0, 0};
	vertices[numVertices] = CGPointMake(textureSize, 0);
	colors[numVertices++] = (ccColor4F){0, 0, 0, 0};
	vertices[numVertices] = CGPointMake(0, textureSize);
	colors[numVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
	vertices[numVertices] = CGPointMake(textureSize, textureSize);
	colors[numVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
	
	glVertexPointer(2, GL_FLOAT, 0, vertices);
	glColorPointer(4, GL_FLOAT, 0, colors);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)numVertices);
	
	// Render top highlight
	float borderWidth = textureSize/16;
	float borderAlpha = 0.3;
	numVertices = 0;
	
	vertices[numVertices] = CGPointMake(0, 0);
	colors[numVertices++] = (ccColor4F){1, 1, 1, borderAlpha};
	vertices[numVertices] = CGPointMake(textureSize, 0);
	colors[numVertices++] = (ccColor4F){1, 1, 1, borderAlpha};

	vertices[numVertices] = CGPointMake(0, borderWidth);
	colors[numVertices++] = (ccColor4F){0, 0, 0, 0};
	vertices[numVertices] = CGPointMake(textureSize, borderWidth);
	colors[numVertices++] = (ccColor4F){0, 0, 0, 0};
	
	glVertexPointer(2, GL_FLOAT, 0, vertices);
	glColorPointer(4, GL_FLOAT, 0, colors);
	glBlendFunc(GL_DST_COLOR, GL_ONE_MINUS_SRC_ALPHA);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)numVertices);
	
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnable(GL_TEXTURE_2D);
	
	// Render Noise
    CCSprite *noise = [CCSprite spriteWithFile:@"noise.png"];
    [noise setBlendFunc:(ccBlendFunc){GL_DST_COLOR, GL_ZERO}];
    noise.position = ccp(textureSize/2, textureSize/2);
    [noise visit];        
	
	[textureRenderer end];
	
	return [CCSprite spriteWithTexture:textureRenderer.sprite.texture];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (ccColor4F)_randomBrightColor
{
	while(1) {
		float requiredBrightness = 192;
		ccColor4B randomColor = ccc4(arc4random()%255, 
									 arc4random()%255, 
									 arc4random()%255, 
									 255);
		if(randomColor.r > requiredBrightness ||
		   randomColor.g > requiredBrightness ||
		   randomColor.b > requiredBrightness) {
			return ccc4FFromccc4B(randomColor);
		}
	}
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)update:(ccTime)dt
{
    float pixelsPerSecond = 100;
    static float offset = 0;
    offset += pixelsPerSecond * dt;
    
    CGSize textureSize = _backgroundSprite.textureRect.size;
    [_backgroundSprite setTextureRect:CGRectMake(offset, 0, textureSize.width, textureSize.height)];
}

@end
