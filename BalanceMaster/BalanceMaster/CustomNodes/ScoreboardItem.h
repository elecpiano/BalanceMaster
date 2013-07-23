//
//  Scoreboard.h
//  BalanceMaster
//
//  Created by Lee Jason on 13-7-22.
//  Copyright 2013年 namiapps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface ScoreboardItem : CCNode {
    
}

@property (nonatomic) int number;

-(id)initWithSpritesheet:(CCSpriteBatchNode *)spritesheet Number:(int)number;
-(void)setPosition:(CGPoint)position;
//-(void)increase;
//-(void)decrease;
-(void)setNumber:(int)num;

@end
