//
//  GameLevelLayer.m
//  SuperKoalio
//
//  Created by Jacob Gundersen on 6/4/12.


#import "GameLevelLayer.h"
#import "Player.h"
#import "SimpleAudioEngine.h"

@interface GameLevelLayer()
{
    CCTMXTiledMap *map; 
    Player *player;
    CCTMXLayer *walls; 
    CCTMXLayer *hazards;
    BOOL gameOver;
}
@end

@implementation GameLevelLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	GameLevelLayer *layer = [GameLevelLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super's" return value
	if( (self=[super init]) ) {
        //init goes here
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"level1.mp3"];
        
        // blue sky background
        CCLayerColor *blueSky = [[CCLayerColor alloc] initWithColor:ccc4(100, 100, 250, 255)];
        [self addChild:blueSky];
        
        // map generated in tiled map editor
        map = [[CCTMXTiledMap alloc] initWithTMXFile:@"level1.tmx"];
        [self addChild:map];
        
        // add the walls
        walls = [map layerNamed:@"walls"];
        // add hazards
        hazards = [map layerNamed:@"hazards"];
        
        // add the player
        player = [[Player alloc] initWithFile:@"koalio_stand.png"];
        player.position = ccp(100, 50);
        [map addChild:player];
        
        // call the update function regularly
        [self schedule:@selector(update:)];
        
        self.isTouchEnabled = YES;
	}
	return self;
}

- (void)update:(ccTime)dt
{
    if (gameOver) {
        return;
    }
    [player update:dt];
    if (![self isPlayerGoingOverboard]) {
        [self handleHazardCollisions:player];
        [self checkForWin];
        [self checkForAndResolveCollisions:player];
        [self setViewPointCenter:player.position];
    }
}

- (BOOL)isPlayerGoingOverboard
{
    BOOL retVal = NO;
    if (player.desiredPosition.x <= 20.0) {
        NSLog(@"going overboard");
        player.desiredPosition = CGPointMake(5.0, player.desiredPosition.y);
        retVal = YES;
    }
    if (player.desiredPosition.y >= 300.0) {
        NSLog(@"going overboard");
        player.desiredPosition = CGPointMake(player.desiredPosition.x, 285.0);
        retVal = YES;
    }
    return retVal;
}

#pragma mark - helper methods

- (CGPoint)tileCoordForPosition:(CGPoint)position
{
    // calculate the player position
    float x = floor(position.x / map.tileSize.width);
    float levelHeightInPixels = map.mapSize.height * map.tileSize.height;
    float y = floor((levelHeightInPixels-position.y) / map.tileSize.height);
    return ccp(x, y);
}

- (CGRect)tileRectFromTileCoords:(CGPoint)tileCoords
{
    // take a tile’s coordinates and returns the rect in Cocos2D coordinates
    float levelHeightInPixels = map.mapSize.height * map.tileSize.height;
    CGPoint origin = ccp(tileCoords.x*map.tileSize.width, levelHeightInPixels-((tileCoords.y+1)*map.tileSize.height));
    return CGRectMake(origin.x, origin.y, map.tileSize.width, map.tileSize.height);
}

- (void)setViewPointCenter:(CGPoint)position
{
    // adjust the screen as player moves along
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    
    int x = MAX(position.x, winSize.width/2);
    int y = MAX(position.y, winSize.height/2);
    x = MIN(x, (map.mapSize.width*map.tileSize.width)-winSize.width/2);
    y = MIN(y, (map.mapSize.height*map.tileSize.height)-winSize.height/2);
    CGPoint actualPosition = ccp(x, y);
    
    CGPoint centerOfView = ccp(winSize.width/2, winSize.height/2);
    CGPoint viewPoint = ccpSub(centerOfView, actualPosition);
    map.position = viewPoint;
}

- (void)handleHazardCollisions:(Player *)_player
{
    NSArray *tiles = [self getSurroundingTilesAtPosition:_player.position forLayer:hazards];
    for (NSDictionary *tile in tiles) {
        CGRect tileRect = CGRectMake([[tile objectForKey:@"x"] floatValue], [[tile objectForKey:@"y"] floatValue], map.tileSize.width, map.tileSize.height);
        CGRect pRect = [_player collisionBoundingBox];
        
        if ([[tile objectForKey:@"gid"] intValue] && CGRectIntersectsRect(pRect, tileRect)) {
            [self gameOver:0];
        }
    }
}

- (void)checkForWin
{
    if (player.position.x > 3150.0) {
        [self gameOver:1];
    }
}

#pragma mark - collision detection methods

- (NSArray *)getSurroundingTilesAtPosition:(CGPoint)position forLayer:(CCTMXLayer *)layer
{
    // retrieve the tile coordinates for the input position
    CGPoint plPos = [self tileCoordForPosition:position];
    
    // return array that has all the tile information
    NSMutableArray *gids = [NSMutableArray array];
    
    // run loop for all possible spaces including player's (9)
    // we only really needed 8, but we don't want to handle skipping that one tile
    // so we'll just include the player tile and remove it later
    for (int i=0; i<9; i++) {
        
        // calculate the position of the current tile
        int c = i % 3;
        int r = (int)(i/3);
        CGPoint tilePos = ccp(plPos.x+(c-1), plPos.y+(r-1));
        
        // check if player fell in a hole
        if (tilePos.y > (map.mapSize.height-1)) {
            [self gameOver:0];
            return nil;
        }
        
        // get the GID of the tile at a specific tile coordinate
        // zero means no tile found
        int tgid = [layer tileGIDAt:tilePos];
        
        // calculate the cocos2d coords for this tile's cgrect
        CGRect tileRect = [self tileRectFromTileCoords:tilePos];
        
        // store all relevant info for this tile
        NSDictionary *tileDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithInt:tgid],@"gid",
                                  [NSNumber numberWithFloat:tileRect.origin.x], @"x",
                                  [NSNumber numberWithFloat:tileRect.origin.y], @"y",
                                  [NSValue valueWithCGPoint:tilePos], @"tilePos",
                                  nil];
        
        // add tile info to return array
        [gids addObject:tileDict];
    }
    
    // remove the player tile as promised
    [gids removeObjectAtIndex:4];

    // re-arrange according to priority
    // resolve that which is N.E.W.S. to the player first
    // the new order will start with S(outh) of player
    [gids insertObject:[gids objectAtIndex:2] atIndex:6];
    [gids removeObjectAtIndex:2];
    [gids exchangeObjectAtIndex:4 withObjectAtIndex:6];
    [gids exchangeObjectAtIndex:0 withObjectAtIndex:4];
    
    /* // just output log
    for (NSDictionary *gid in gids) {
        NSLog(@"%@", gid);
    } */
    
    return (NSArray *)gids;
}

- (void)checkForAndResolveCollisions:(Player *)p
{
    // get the tiles that surround the player
    NSArray *tiles = [self getSurroundingTilesAtPosition:p.position forLayer:walls];
    
    if (gameOver) {
        return;
    }
    
    p.onGround = NO;
    
    // loop through each tile in that set
    for (NSDictionary *dic in tiles) {
        
        // get the player's bounds aka bounding box
        CGRect pRect = [p collisionBoundingBox];
        
        // get the tile info (GID), if there is one
        int gid = [[dic objectForKey:@"gid"] intValue];
        if (gid) {
        
            // get the bounds of the tile
            CGRect tileRect = CGRectMake([[dic objectForKey:@"x"] floatValue], [[dic objectForKey:@"y"] floatValue], map.tileSize.width, map.tileSize.height);
            
            // see if we have a collision
            if (CGRectIntersectsRect(pRect, tileRect)) {
                
                // get the bounds of this intersection
                CGRect intersection = CGRectIntersection(pRect, tileRect);
                
                // get the tile index number (N.E.W.S only)
                int tileIndx = [tiles indexOfObject:dic];
                
                // determine how we are going to update the desired position
                // based from what sort of intersection the player and the tile is having
                if (tileIndx == 0) {
                    // tile is directly below player
                    p.desiredPosition = ccp(p.desiredPosition.x, p.desiredPosition.y + intersection.size.height);
                    // reset player velocity
                    p.velocity = ccp(p.velocity.x, 0.0);
                    p.onGround = YES;
                } else if (tileIndx == 1) {
                    // tile is directly above player
                    p.desiredPosition = ccp(p.desiredPosition.x, p.desiredPosition.y - intersection.size.height);
                    // reset player velocity
                    p.velocity = ccp(p.velocity.x, 0.0);
                } else if (tileIndx == 2) {
                    // tile is left of player
                    p.desiredPosition = ccp(p.desiredPosition.x + intersection.size.width, p.desiredPosition.y);
                } else if (tileIndx == 3) {
                    // tile is right of player
                    p.desiredPosition = ccp(p.desiredPosition.x - intersection.size.width, p.desiredPosition.y);
                } else {
                    // tile is diagonal to player
                    // if wide, then resolve vertically; if tall, then horizontally
                    if (intersection.size.width > intersection.size.height) {
                        // tile is diagonal, but resolving collision vertically
                        float intersectionHeight;
                        // reset velocity
                        p.velocity = ccp(p.velocity.x, 0.0);
                        // check to whether move up or down
                        if (tileIndx > 5) {
                            intersectionHeight = intersection.size.height;
                        } else {
                            intersectionHeight = -intersection.size.height;
                        }
                        p.desiredPosition = ccp(p.desiredPosition.x, p.desiredPosition.y+intersection.size.height);
                        p.onGround = YES;
                    } else {
                        // tile is diagonal, but resolvising collision horizontally
                        float resolutionWidth;
                        // check to whether move up or down
                        if (tileIndx==6 || tileIndx==4) {
                            resolutionWidth = intersection.size.width;
                        } else {
                            resolutionWidth = -intersection.size.width;
                        }
                        p.desiredPosition = ccp(p.desiredPosition.x, p.desiredPosition.y+resolutionWidth);
                    }
                }
            }
        }
    }
    // set the position to whatever we deem as the desired position
    p.position = p.desiredPosition;
}

#pragma mark - touch handling methods

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"Touches began");
    player.backwardMarch = NO;
    for (UITouch *t in touches) {
        CGPoint touchLocation = [self convertTouchToNodeSpace:t];
        // check if user touches the right(forward) side of the screen
        if (touchLocation.x > 240) {
            player.forwardMarch = YES;
        } else {
            player.mightAsWellJump = YES;
        }
    }
}

- (void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"Touches moved");
    for (UITouch *t in touches) {
        CGPoint touchLocation = [self convertTouchToNodeSpace:t];
        
        // get previous touch and convert it to node space
        CGPoint previousTouchLocation = [t previousLocationInView:[t view]];
        CGSize screenSize = [[CCDirector sharedDirector] winSize];
        // we have to flip values so we need to know the previous touch location
        previousTouchLocation = ccp(previousTouchLocation.x, screenSize.height - previousTouchLocation.y);
        
        if (touchLocation.x > 240 && previousTouchLocation.x <= 240) {
            player.mightAsWellJump = NO;
            player.forwardMarch = YES;
        } else if (previousTouchLocation.x > 240 && touchLocation.x <= 240+5) {
            player.backwardMarch = YES;
            player.forwardMarch = NO;
        }
    }
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"Touches ended");
    for (UITouch *t in touches) {
        CGPoint touchLocation = [self convertTouchToNodeSpace:t];
        if (touchLocation.x < 240) {
            player.mightAsWellJump = NO;
        } else {
            player.forwardMarch = NO;
            player.backwardMarch = NO;
        }
    }
}

#pragma mark - game state methods

-(void)gameOver:(BOOL)won {
	gameOver = YES;
	NSString *gameText;
	
	if (won) {
		gameText = @"You Won!";
	} else {
		gameText = @"You have Died!";
        [[SimpleAudioEngine sharedEngine] playEffect:@"hurt.wav"];
	}
	
    CCLabelTTF *diedLabel = [[CCLabelTTF alloc] initWithString:gameText fontName:@"Marker Felt" fontSize:40];
    diedLabel.position = ccp(240, 200);
    CCMoveBy *slideIn = [[CCMoveBy alloc] initWithDuration:1.0 position:ccp(0, 250)];
    CCMenuItemImage *replay = [[CCMenuItemImage alloc] initWithNormalImage:@"replay.png" selectedImage:@"replay.png" disabledImage:@"replay.png" block:^(id sender) {
        [[CCDirector sharedDirector] replaceScene:[GameLevelLayer scene]];
    }];
    
    NSArray *menuItems = [NSArray arrayWithObject:replay];
    CCMenu *menu = [[CCMenu alloc] initWithArray:menuItems];
    menu.position = ccp(240, -100);
    
    [self addChild:menu];
    [self addChild:diedLabel];
    
    [menu runAction:slideIn];
}

@end
