//
//  Gem.h
//  Chainz
//
//  Created by Pedro Gomes on 12/13/11.
//  Copyright (c) 2011 Phluid Labs. All rights reserved.
//

#import "CCSprite.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
typedef enum {
	GemKindNormal,
	GemKindSpecialPower,
	GemKindCount // must be last
} GemKind;

typedef enum {
	GemColorBlue,
	GemColorOrange,
	GemColorPurple,
	GemColorRed,
	GemColorWhite,
	GemColorYellow,
	GemColorCount // must be last
} GemColor;

typedef enum {
	GemBoostNone,
	GemBoostExplosive,
} GemAttribute;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@class Gameboard;
@interface Gem : CCSprite
{
	GemKind				_kind;
	GemColor			_color;
	GemAttribute		_attributes;
	
	__weak Gameboard	*_gameboard;
	CGPoint				_point;
}

@property (nonatomic, readonly) GemKind kind;
@property (nonatomic, readonly) GemColor gemColor;
@property (nonatomic, readonly) GemAttribute attributes;
@property (nonatomic, assign) CGPoint point;

- (id)initWithGameboard:(Gameboard *)gameboard position:(CGPoint)point kind:(GemKind)kind;
- (id)initWithGameboard:(Gameboard *)gameboard position:(CGPoint)point kind:(GemKind)kind color:(GemColor)color;
- (id)initWithGameboard:(Gameboard *)gameboard position:(CGPoint)point kind:(GemKind)kind color:(GemColor)color attributes:(GemAttribute)attribute;

- (void)updatePosition:(CGPoint)point;

// Animations and Effects

//- (void)wobble;
//- (void)explode;
//- (void)shrink;

@end
