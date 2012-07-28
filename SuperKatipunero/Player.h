//
//  Player.h
//  SuperKoalio
//
//  Created by Jacob Gundersen on 6/4/12.
//  Copyright 2012 Interrobang Software LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface Player : CCSprite

@property (nonatomic, assign) CGPoint velocity;
@property (nonatomic, assign) CGPoint desiredPosition;
@property (nonatomic, assign) BOOL onGround;
@property (nonatomic, assign) BOOL forwardMarch;
@property (nonatomic, assign) BOOL backwardMarch;
@property (nonatomic, assign) BOOL mightAsWellJump;

- (void)update:(ccTime)dt;
- (CGRect)collisionBoundingBox;

@end
