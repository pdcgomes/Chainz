//
//  Gem.h
//  Chainz
//
//  Created by Pedro Gomes on 12/13/11.
//  Copyright (c) 2011 Phluid Labs. All rights reserved.
//

#import "cocos2d.h"

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
typedef enum {
	GemKindNormal,
	GemKindSpecialPower,
	GemKindCount // must be last
} GemKind;

typedef enum {
	GemColorGreen,
	GemColorBlue,
	GemColorMagenta,
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
@class GameBoard;
@interface Gem : CCSprite <CCTargetedTouchDelegate>
{
	GemKind				_kind;
	GemColor			_color;
	GemAttribute		_attributes;
	
	__weak GameBoard	*_gameboard;
	CGPoint				_point;
	
	BOOL				_selected;
	BOOL				_moved;
	CGPoint				_firstTouchLocation;
}

@property (nonatomic, readonly) GemKind kind;
@property (nonatomic, readonly) GemColor gemColor;
@property (nonatomic, readonly) GemAttribute attributes;
@property (nonatomic, assign) CGPoint point;
@property (nonatomic, readonly) BOOL selected;

- (id)initWithGameboard:(GameBoard *)gameboard position:(CGPoint)point kind:(GemKind)kind;
- (id)initWithGameboard:(GameBoard *)gameboard position:(CGPoint)point kind:(GemKind)kind color:(GemColor)color;
- (id)initWithGameboard:(GameBoard *)gameboard position:(CGPoint)point kind:(GemKind)kind color:(GemColor)color attributes:(GemAttribute)attribute;

- (void)updatePosition:(CGPoint)point;
- (void)markSelected:(BOOL)selected;

// Animations and Effects

//- (void)wobble;
//- (void)explode;
//- (void)shrink;

@end
