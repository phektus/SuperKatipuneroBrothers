//
//  Player.m
//  SuperKoalio
//
//  Created by Jacob Gundersen on 6/4/12.
//  Copyright 2012 Interrobang Software LLC. All rights reserved.
//

#import "Player.h"
#import "SimpleAudioEngine.h"

@implementation Player

@synthesize velocity = _velocity;
@synthesize desiredPosition = _desiredPosition;
@synthesize onGround = _onGround;
@synthesize forwardMarch = _forwardMarch;
@synthesize backwardMarch = _backwardMarch;
@synthesize mightAsWellJump = _mightAsWellJump;

-(id)initWithFile:(NSString *)filename {
    if (self = [super initWithFile:filename]) {
        self.velocity = ccp(0.0, 0.0);
    }
    return self;
}

- (void)update:(ccTime)dt
{
    //NSLog(@"Current position: %f, %f", self.position.x, self.position.y);
    
    // jump mechanism
    CGPoint jumpForce = ccp(0.0, 310.0);
    float jumpCutoff = 150.0;
    if (self.mightAsWellJump && self.onGround) {
        self.velocity = ccpAdd(self.velocity, jumpForce);
        [[SimpleAudioEngine sharedEngine] playEffect:@"jump.wav"];
    } else if (!self.mightAsWellJump && self.velocity.y > jumpCutoff) {
        self.velocity = ccp(self.velocity.x, jumpCutoff);
    }
    
    // gravity force
    CGPoint gravity = ccp(0.0, -450.0);
    // scale it according to the current time frame
    CGPoint gravityStep = ccpMult(gravity, dt);
    
    // move force
    CGPoint movement = ccp(800.0, 0.0);
    // scale it according to the current time frame
    CGPoint moveStep = ccpMult(movement, dt);
    
    // dampen a bit to simulate friction
    self.velocity = ccp(self.velocity.x*0.90, self.velocity.y);
    
    // only add the forward force where applicable
    if (self.forwardMarch || self.backwardMarch) {
        self.velocity = ccpAdd(self.velocity, moveStep);
    }
    //NSLog(@"Velocity after move: %f, %f", self.velocity.x, self.velocity.y);
    
    // apply clamps so movement doesn't go overboard
    // max speed has to be reached w/in a sec or less
    CGPoint minMovement = ccp(0.0, -450.0);
    CGPoint maxMovement = ccp(220.0, 250.0);
    self.velocity = ccpClamp(self.velocity, minMovement, maxMovement);
    //NSLog(@"Velocity after clamp: %f, %f", self.velocity.x, self.velocity.y);
    
    // introduce gravity
    self.velocity = ccpAdd(self.velocity, gravityStep);
    
    // apply the velocity to where the desired position is
    CGPoint stepVelocity = ccpMult(self.velocity, dt);
    NSLog(@"Step velocity: %f, %f", stepVelocity.x, stepVelocity.y);
    
    // check for backward movement
    if (self.backwardMarch) {
        stepVelocity = ccp((stepVelocity.x)*(-1.0), stepVelocity.y);
    }
    
    self.desiredPosition = ccpAdd(self.position, stepVelocity);
    //NSLog(@"Desired position: %f, %f", self.desiredPosition.x, self.desiredPosition.y);
}

- (CGRect)collisionBoundingBox
{
    // compute the bounding box based on the desired position
    CGRect collisionBox = CGRectInset(self.boundingBox, 3, 0);
    CGPoint diff = ccpSub(self.desiredPosition, self.position);
    return CGRectOffset(collisionBox, diff.x, diff.y);
}

@end
