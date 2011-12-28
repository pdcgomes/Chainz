//
//  Gem.m
//  Chainz
//
//  Created by Pedro Gomes on 12/13/11.
//  Copyright (c) 2011 Phluid Labs. All rights reserved.
//

#import "Gem.h"
#import "GameBoard.h"
#import "CCDrawingPrimitives.h"

////////////////////////////////////////////////////////////////////////////////
// Utility functions
////////////////////////////////////////////////////////////////////////////////
NSString *GemKindString(GemKind kind) 
{
	switch(kind)
	{
		case GemKindNormal:			return @"normal";
		case GemKindEmpty:			return @"empty";
		case GemKindSpecialPower:	return @"special";
		default: return [NSString stringWithFormat:@"unknown gem kind %d", kind];
	}
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
NSString *GemColorString(GemColor color) 
{
	switch(color) 
	{
		case GemColorBlue: 		return @"blue";
		case GemColorRed: 		return @"red";
		case GemColorGreen: 	return @"green";
		case GemColorMagenta: 	return @"magenta";
		case GemColorOrange: 	return @"orange";
		case GemColorPurple: 	return @"purple";
		case GemColorWhite: 	return @"white";
		case GemColorYellow: 	return @"yellow";
		default: return [NSString stringWithFormat:@"unknown gem color %d", color];
	}
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@implementation Gem

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@synthesize kind 		= _kind;
@synthesize gemColor 	= _color;
@synthesize attributes	= _attributes;
@synthesize point		= _point;
@synthesize selected	= _selected;

#pragma mark - Dealloc and Initialization
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)dealloc
{
	[super dealloc];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (id)initWithGameboard:(GameBoard *)gameboard position:(CGPoint)point kind:(GemKind)kind
{
	return [self initWithGameboard:gameboard position:point kind:kind color:arc4random()%GemColorCount attributes:GemBoostNone];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (id)initWithGameboard:(GameBoard *)gameboard position:(CGPoint)point kind:(GemKind)kind color:(GemColor)color
{
	return [self initWithGameboard:gameboard position:point kind:kind color:color attributes:GemBoostNone];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (id)initWithGameboard:(GameBoard *)gameboard position:(CGPoint)point kind:(GemKind)kind color:(GemColor)color attributes:(GemAttribute)attribute
{
	CCTexture2D *texture = [[CCTextureCache sharedTextureCache] addImage:@"ball.png"];
	if((self = [super initWithTexture:texture])) {
		// TODO: load the actual texture/image
		_gameboard 	= gameboard;
		_point 		= point;
		_color		= color;
		_attributes	= attribute;

        ccColor3B spriteColor;
        switch(color) {
            case GemColorRed:       spriteColor = ccRED; break;
            case GemColorBlue:      spriteColor = ccBLUE; break;
            case GemColorGreen:     spriteColor = ccGREEN; break;
            case GemColorMagenta:   spriteColor = ccMAGENTA; break;
            case GemColorOrange:    spriteColor = ccORANGE; break;
            case GemColorPurple:    spriteColor = ccc3(132, 0, 255); break;
            case GemColorYellow:    spriteColor = ccYELLOW; break;
            case GemColorWhite:     spriteColor = ccWHITE;
            default: break;
        }
        
		[self setAnchorPoint:CGPointZero];
		[self setColor:spriteColor];
		CCLabelTTF *label = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", color] fontName:@"Marker Felt" fontSize:12];
		[self addChild:label];
	}
	return self;
}

#pragma mark - CCNode

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//- (void)draw
//{
//	[super draw];
//
//	CGFloat radius = 20.0;
//	CGFloat segments = 10;
//	ccDrawCircle((CGPoint){self.position.x + radius, self.position.y + radius}, radius, 0, segments, YES);
//}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)onEnter
{
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
	[super onEnter];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)onExit
{
	[[CCTouchDispatcher sharedDispatcher] removeDelegate:self];
	[super onExit];
}

#pragma mark - CCTargetedTouchDelegate

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint touchLocation = [touch locationInView:touch.window];
	CGPoint touchLocationFlipped = {touchLocation.x, [[CCDirector sharedDirector] winSize].height - touchLocation.y};
	CGRect spriteRect = (CGRect){self.position, rect_.size};
	
	if(CGRectContainsPoint(spriteRect, touchLocationFlipped)) {
		CCLOG(@"Touched gem %@", NSStringFromCGPoint(self.point));
		_firstTouchLocation = touchLocationFlipped;
		_moved = NO;
		return YES;
	}
	return NO;
	
	CCLOG(@"Gameboard touch location = %@, sprite_frame = %@", NSStringFromCGPoint(touchLocation), NSStringFromCGRect((CGRect){self.position, rect_.size}));
//	CCLOG(@"Gameboard gem index = %@", NSStringFromCGPoint(CoordinatesForWindowLocation(p)));
	return YES;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
	_moved = YES;
}

//////////////////////////////////////////////////////////////////////////////////
// Note: consider moving the gem touch handling logic to the gameboard itself
// besided the potential improvement in performance (individual gems don't have to handle touches)
// it's probably a much more flexible design
//////////////////////////////////////////////////////////////////////////////////
- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
	if(!_moved) {
		[_gameboard selectGem:self];
	}
	else {
		// TODO: add a minimum offset threshold to trigger the actual swipe, otherwise consider it a single tap
		CGPoint endTouchLocation = [touch locationInView:touch.window];
		CGPoint endTouchLocationFlipped = {endTouchLocation.x, [[CCDirector sharedDirector] winSize].height - endTouchLocation.y};
		
		// vertical or horizontal?
		CGFloat horizontalOffset = endTouchLocationFlipped.x - _firstTouchLocation.x;
		CGFloat verticalOffset = endTouchLocationFlipped.y - _firstTouchLocation.y;
		
		GameboardMovementDirection direction = GameboardMovementDirectionInvalid;
		if(fabs(horizontalOffset) >= fabs(verticalOffset)) { // moved horizontally
			if(horizontalOffset > 0) 		direction = GameboardMovementDirectionRight;
			else if(horizontalOffset < 0) 	direction = GameboardMovementDirectionLeft;
		}
		else {
			if(verticalOffset > 0)			direction = GameboardMovementDirectionUp;
			else if(verticalOffset < 0) 	direction = GameboardMovementDirectionDown;
		}
		
		if(![_gameboard moveGemAtPoint:self.point withDirection:direction]) {
//			CCLOGINFO(@"Invalid move %@ => %@", NSStringFromCGPoint(self.point), );
		}
	}

	_firstTouchLocation = CGPointZero;
	_moved = NO;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
	_firstTouchLocation = CGPointZero;
	_moved = NO;
}

#pragma mark - Public Methods

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)updatePosition:(CGPoint)point
{
	
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
- (void)markSelected:(BOOL)selected
{
	_selected = selected;
	if(_selected) {
		// draw selected mode
	}
	else {
		// clear selected mode
	}
}

#pragma mark - Animations and Effects

- (void)wobble
{
	
}

- (void)explode
{
	
}

- (void)shrink
{
	
}


@end
