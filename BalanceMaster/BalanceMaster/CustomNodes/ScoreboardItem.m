//
//  Scoreboard.m
//  BalanceMaster
//
//  Created by Lee Jason on 13-7-22.
//  Copyright 2013年 namiapps. All rights reserved.
//

#import "ScoreboardItem.h"

#define FLIP_DURATION 0.1

@implementation ScoreboardItem{
    CCSpriteBatchNode *_spritesheet;
    
    CCSprite *sprite_u;
    CCSprite *sprite_d;
    CCSprite *sprite_au;//'a' for animation
    CCSprite *sprite_ad;
    
    NSMutableArray *frames_u;
    NSMutableArray *frames_d;
    
    int currentNumber;
}

-(id)initWithSpritesheet:(CCSpriteBatchNode *)spritesheet Number:(int)number{
    if ((self = [super init])) {
        _spritesheet = spritesheet;
      
        [self initFrames];
        
        sprite_u = [CCSprite spriteWithSpriteFrame:[frames_u objectAtIndex:number]];
        sprite_u.anchorPoint = ccp(0.5, 0);
        [_spritesheet addChild:sprite_u];
        sprite_d = [CCSprite spriteWithSpriteFrame:[frames_d objectAtIndex:number]];
        sprite_d.anchorPoint = ccp(0.5, 1);
        [_spritesheet addChild:sprite_d];
        
        sprite_au = [CCSprite spriteWithSpriteFrame:[frames_u objectAtIndex:number]];
        sprite_au.anchorPoint = ccp(0.5, 0);
        sprite_au.scaleY = 0;
        [_spritesheet addChild:sprite_au];
        
        sprite_ad = [CCSprite spriteWithSpriteFrame:[frames_d objectAtIndex:number]];
        sprite_ad.anchorPoint = ccp(0.5, 1);
        sprite_ad.scaleY = 0;
        [_spritesheet addChild:sprite_ad];
        
        currentNumber = number;
    }
    return self;
}

-(void)initFrames{
    frames_u = [[NSMutableArray alloc] init];
    frames_d = [[NSMutableArray alloc] init];
    
    [frames_u addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"0u.png"]];
    [frames_u addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"1u.png"]];
    [frames_u addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"2u.png"]];
    [frames_u addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"3u.png"]];
    [frames_u addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"4u.png"]];
    [frames_u addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"5u.png"]];
    [frames_u addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"6u.png"]];
    [frames_u addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"7u.png"]];
    [frames_u addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"8u.png"]];
    [frames_u addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"9u.png"]];

    [frames_d addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"0d.png"]];
    [frames_d addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"1d.png"]];
    [frames_d addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"2d.png"]];
    [frames_d addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"3d.png"]];
    [frames_d addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"4d.png"]];
    [frames_d addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"5d.png"]];
    [frames_d addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"6d.png"]];
    [frames_d addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"7d.png"]];
    [frames_d addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"8d.png"]];
    [frames_d addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"9d.png"]];
}

#pragma mark - Position
-(void)setPosition:(CGPoint)position{
    sprite_u.position = sprite_d.position = sprite_au.position = sprite_ad.position = position;
    [super setPosition:position];
}

-(int)getNextNumber:(int)num{
    num ++;
    if (num > 9) {
        num = 0;
    }
    return num;
}

-(int)getPreviousNumber:(int)num{
    num --;
    if (num < 0) {
        num = 9;
    }
    return num;
}

-(void)beginSetNumberFrom:(int)from To:(int)to{
    currentNumber = to;
    [sprite_u setDisplayFrame:[frames_u objectAtIndex:to]];
    [sprite_au setDisplayFrame:[frames_u objectAtIndex:from]];
    sprite_au.scaleY = 1;
    
    CCScaleTo *scaleAction = [CCScaleTo actionWithDuration:FLIP_DURATION scaleX:1 scaleY:0];
    CCCallFunc *callFuncAction = [CCCallFunc actionWithTarget:self selector:@selector(continueSetNumber)];
    CCSequence *sequenceAction = [CCSequence actions:scaleAction,callFuncAction, nil];
    [sprite_au runAction:sequenceAction];
}

-(void)continueSetNumber{
    [sprite_ad setDisplayFrame:[frames_d objectAtIndex:currentNumber]];
    CCScaleTo *scaleAction = [CCScaleTo actionWithDuration:FLIP_DURATION scaleX:1 scaleY:1];
    CCCallFunc *callFuncAction = [CCCallFunc actionWithTarget:self selector:@selector(finishSetNumber)];
    CCSequence *sequenceAction = [CCSequence actions:scaleAction,callFuncAction, nil];
    [sprite_ad runAction:sequenceAction];
}

-(void)finishSetNumber{
    [sprite_d setDisplayFrame:[frames_d objectAtIndex:currentNumber]];
    sprite_ad.scaleY = 0;
}

-(void)increase{
    [self beginSetNumberFrom:currentNumber To:[self getNextNumber:currentNumber]];
}

-(void)decrease{
    [self beginSetNumberFrom:currentNumber To:[self getPreviousNumber:currentNumber]];
}

@end
