//
//  SettingsLayer.m
//  BalanceMaster
//
//  Created by Lee Jason on 13-7-31.
//  Copyright 2013年 namiapps. All rights reserved.
//

#import "SettingsLayer.h"
#import "HelloWorldLayer.h"
#import "GlobalData.h"

@implementation SettingsLayer{
    CGSize WIN_SIZE;
    CCSpriteBatchNode *spritesheet;
    CCMenuItemSprite *menuItemPlus_X, *menuItemMinus_X, *menuItemPlus_Y, *menuItemMinus_Y, *menuItemPlus_Z, *menuItemMinus_Z, *menuItemOK, *menuItemRestore;
    CCSprite *sliderBar_X, *sliderBar_Y, *sliderBar_Z;
    CCLabelTTF *labelX, *labelY, *labelZ;
}

+(CCScene *) scene{
	CCScene *scene = [CCScene node];
	SettingsLayer *layer = [SettingsLayer node];
	[scene addChild: layer];
	return scene;
}

#pragma mark - Lifecycle

-(id) init{
	if( (self=[super init])) {
        //global
        WIN_SIZE = [CCDirector sharedDirector].winSize;
        
        //load spritesheet
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"Textures.plist"];
        spritesheet = [CCSpriteBatchNode batchNodeWithFile:@"Textures.png"];
        [self addChild:spritesheet z:0];
        
        //menu buttons
        [self initMenu];
        
        //slider
        [self initSliders];
        
        //load Data
        [self loadData];
        
	}
	return self;
}

#pragma mark - Menu

-(void)initMenu{
    menuItemPlus_X = [CCMenuItemSprite
                     itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"plusButtonNormal.png"]
                     selectedSprite:[CCSprite spriteWithSpriteFrameName:@"plusButtonActive.png"]
                     block:^(id sender) {
                         [self onAdjustSensitivity:YES dimension:0];
                     }];
    menuItemPlus_X.position = ccp(120, 120);
    
    menuItemMinus_X = [CCMenuItemSprite
                     itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"minusButtonNormal.png"]
                     selectedSprite:[CCSprite spriteWithSpriteFrameName:@"minusButtonActive.png"]
                     block:^(id sender) {
                         [self onAdjustSensitivity:NO dimension:0];
                     }];
    menuItemMinus_X.position = ccp(-120, 120);
    
    menuItemPlus_Y = [CCMenuItemSprite
                      itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"plusButtonNormal.png"]
                      selectedSprite:[CCSprite spriteWithSpriteFrameName:@"plusButtonActive.png"]
                      block:^(id sender) {
                          [self onAdjustSensitivity:YES dimension:1];
                      }];
    menuItemPlus_Y.position = ccp(120, 40);
    
    menuItemMinus_Y = [CCMenuItemSprite
                       itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"minusButtonNormal.png"]
                       selectedSprite:[CCSprite spriteWithSpriteFrameName:@"minusButtonActive.png"]
                       block:^(id sender) {
                           [self onAdjustSensitivity:NO dimension:1];
                       }];
    menuItemMinus_Y.position = ccp(-120, 40);
    
    menuItemPlus_Z = [CCMenuItemSprite
                      itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"plusButtonNormal.png"]
                      selectedSprite:[CCSprite spriteWithSpriteFrameName:@"plusButtonActive.png"]
                      block:^(id sender) {
                          [self onAdjustSensitivity:YES dimension:2];
                      }];
    menuItemPlus_Z.position = ccp(120, -40);
    
    menuItemMinus_Z = [CCMenuItemSprite
                       itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"minusButtonNormal.png"]
                       selectedSprite:[CCSprite spriteWithSpriteFrameName:@"minusButtonActive.png"]
                       block:^(id sender) {
                           [self onAdjustSensitivity:NO dimension:2];
                       }];
    menuItemMinus_Z.position = ccp(-120, -40);
    
    menuItemRestore = [CCMenuItemSprite
                       itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"restoreSettingsButtonNormal.png"]
                       selectedSprite:[CCSprite spriteWithSpriteFrameName:@"restoreSettingsButtonActive.png"]
                       block:^(id sender) {
                           [self onRestore];
                       }];
    menuItemRestore.position = ccp(0, -135);
    
    menuItemOK = [CCMenuItemSprite
                  itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"okButtonNormal.png"]
                  selectedSprite:[CCSprite spriteWithSpriteFrameName:@"okButtonActive.png"]
                  block:^(id sender) {
                      [self onOK];
                  }];
    menuItemOK.position = ccp(0, -200);
    
	CCMenu *menu = [CCMenu menuWithItems: menuItemPlus_X, menuItemMinus_X, menuItemPlus_Y, menuItemMinus_Y, menuItemPlus_Z, menuItemMinus_Z, menuItemRestore, menuItemOK, nil];
	[self addChild:menu z:0];
}

-(void)initSliders{
    CCSprite *sliderBase1;
    CCSprite *sliderBase2;
    
    sliderBar_X = [CCSprite spriteWithSpriteFrameName:@"sliderBar.png"];
    sliderBase1 = [CCSprite spriteWithSpriteFrameName:@"sliderBase1.png"];
    sliderBase2 = [CCSprite spriteWithSpriteFrameName:@"sliderBase2.png"];
    sliderBar_X.anchorPoint = ccp(0,0.5);
    sliderBar_X.position = ccp(WIN_SIZE.width/2 - sliderBase1.contentSize.width/2, 360);
    sliderBase1.position = ccp(WIN_SIZE.width/2, 360);
    sliderBase2.position = ccp(WIN_SIZE.width/2, 360);
    [spritesheet addChild:sliderBar_X z:1];
    [spritesheet addChild:sliderBase1 z:0];
    [spritesheet addChild:sliderBase2 z:2];
    
    
    sliderBar_Y = [CCSprite spriteWithSpriteFrameName:@"sliderBar.png"];
    sliderBase1 = [CCSprite spriteWithSpriteFrameName:@"sliderBase1.png"];
    sliderBase2 = [CCSprite spriteWithSpriteFrameName:@"sliderBase2.png"];
    sliderBar_Y.anchorPoint = ccp(0,0.5);
    sliderBar_Y.position = ccp(WIN_SIZE.width/2 - sliderBase1.contentSize.width/2, 280);
    sliderBase1.position = ccp(WIN_SIZE.width/2, 280);
    sliderBase2.position = ccp(WIN_SIZE.width/2, 280);
    [spritesheet addChild:sliderBar_Y z:1];
    [spritesheet addChild:sliderBase1 z:0];
    [spritesheet addChild:sliderBase2 z:2];
    
    
    sliderBar_Z = [CCSprite spriteWithSpriteFrameName:@"sliderBar.png"];
    sliderBase1 = [CCSprite spriteWithSpriteFrameName:@"sliderBase1.png"];
    sliderBase2 = [CCSprite spriteWithSpriteFrameName:@"sliderBase2.png"];
    sliderBar_Z.anchorPoint = ccp(0,0.5);
    sliderBar_Z.position = ccp(WIN_SIZE.width/2 - sliderBase1.contentSize.width/2, 200);
    sliderBase1.position = ccp(WIN_SIZE.width/2, 200);
    sliderBase2.position = ccp(WIN_SIZE.width/2, 200);
    [spritesheet addChild:sliderBar_Z z:1];
    [spritesheet addChild:sliderBase1 z:0];
    [spritesheet addChild:sliderBase2 z:2];
    
    CCLabelTTF *title;
    title = [CCLabelTTF labelWithString:@"设置灵敏度" fontName:@"Arial" fontSize:32];
    title.position = ccp(WIN_SIZE.width/2, WIN_SIZE.height - 30);
    [self addChild:title z:0];

    title = [CCLabelTTF labelWithString:@"左右" fontName:@"Arial" fontSize:24];
    title.position = ccp(WIN_SIZE.width/2 - 50, 385);
    [self addChild:title z:0];

    labelX = [CCLabelTTF labelWithString:@"0" fontName:@"Arial" fontSize:24];
    labelX.position = ccp(WIN_SIZE.width/2 + 50, 385);
    [self addChild:labelX z:0];
    
    title = [CCLabelTTF labelWithString:@"上下" fontName:@"Arial" fontSize:24];
    title.position = ccp(WIN_SIZE.width/2 - 50, 305);
    [self addChild:title z:0];
 
    labelY = [CCLabelTTF labelWithString:@"0" fontName:@"Arial" fontSize:24];
    labelY.position = ccp(WIN_SIZE.width/2 + 50, 305);
    [self addChild:labelY z:0];
    
    title = [CCLabelTTF labelWithString:@"前后" fontName:@"Arial" fontSize:24];
    title.position = ccp(WIN_SIZE.width/2 - 50, 225);
    [self addChild:title z:0];
    
    labelZ = [CCLabelTTF labelWithString:@"0" fontName:@"Arial" fontSize:24];
    labelZ.position = ccp(WIN_SIZE.width/2 + 50, 225);
    [self addChild:labelZ z:0];
}

-(void)loadData{
    [self setSensitivity:[HelloWorldLayer sensitivity_X] dimension:0];
    [self setSensitivity:[HelloWorldLayer sensitivity_Y] dimension:1];
    [self setSensitivity:[HelloWorldLayer sensitivity_Z] dimension:2];
}

-(void)onAdjustSensitivity:(BOOL)toAdd dimension:(int)dimension{
    if (dimension == 0) {
        if (toAdd && [HelloWorldLayer sensitivity_X]<10) {
            [HelloWorldLayer setSensitivity_X:[HelloWorldLayer sensitivity_X]+1];
        }
        else if (!toAdd && [HelloWorldLayer sensitivity_X]>1){
            [HelloWorldLayer setSensitivity_X:[HelloWorldLayer sensitivity_X]-1];
        }
        [self setSensitivity:[HelloWorldLayer sensitivity_X] dimension:dimension];
    }
    else if (dimension == 1){
        if (toAdd && [HelloWorldLayer sensitivity_Y]<10) {
            [HelloWorldLayer setSensitivity_Y:[HelloWorldLayer sensitivity_Y]+1];
        }
        else if (!toAdd && [HelloWorldLayer sensitivity_Y]>1){
            [HelloWorldLayer setSensitivity_Y:[HelloWorldLayer sensitivity_Y]-1];
        }
        [self setSensitivity:[HelloWorldLayer sensitivity_Y] dimension:dimension];
    }
    else if (dimension == 2){
        if (toAdd && [HelloWorldLayer sensitivity_Z]<10) {
            [HelloWorldLayer setSensitivity_Z:[HelloWorldLayer sensitivity_Z]+1];
        }
        else if (!toAdd && [HelloWorldLayer sensitivity_Z]>1){
            [HelloWorldLayer setSensitivity_Z:[HelloWorldLayer sensitivity_Z]-1];
        }
        [self setSensitivity:[HelloWorldLayer sensitivity_Z] dimension:dimension];
    }
}

-(void)setSensitivity:(int)amount dimension:(int)dimension{
    if (dimension == 0) {
        sliderBar_X.scaleX = amount * 0.1;
        [labelX setString:[NSString stringWithFormat:@"%d", amount]];
    }
    else if (dimension == 1){
        sliderBar_Y.scaleX = amount * 0.1;
        [labelY setString:[NSString stringWithFormat:@"%d", amount]];
    }
    else if (dimension == 2){
        sliderBar_Z.scaleX = amount * 0.1;
        [labelZ setString:[NSString stringWithFormat:@"%d", amount]];
    }
}

-(void)onRestore{
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DefaultSettings" ofType:@"plist"]];

    [HelloWorldLayer setSensitivity_X:[(NSNumber *)[dict objectForKey:kSensitivity_X] intValue]];
    [HelloWorldLayer setSensitivity_Y:[(NSNumber *)[dict objectForKey:kSensitivity_Y] intValue]];
    [HelloWorldLayer setSensitivity_Z:[(NSNumber *)[dict objectForKey:kSensitivity_Z] intValue]];
    
    [self loadData];
}

-(void)onOK{    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:[HelloWorldLayer sensitivity_X] forKey:kSensitivity_X];
    [userDefaults setInteger:[HelloWorldLayer sensitivity_Y] forKey:kSensitivity_Y];
    [userDefaults setInteger:[HelloWorldLayer sensitivity_Z] forKey:kSensitivity_Z];
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:0.5 scene:[HelloWorldLayer scene] ]];
}

@end
