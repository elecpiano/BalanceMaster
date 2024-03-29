//
//  HelloWorldLayer.mm
//  BalanceMaster
//
//  Created by Lee Jason on 13-7-20.
//  Copyright namiapps 2013年. All rights reserved.
//

// Import the interfaces
#import "HelloWorldLayer.h"
#import "CCPhysicsSprite.h"
#import "AppDelegate.h"
#import "GB2ShapeCache.h"
#import "SimpleAudioEngine.h"
#import "ScoreboardItem.h"
#import "SettingsLayer.h"
#import "GlobalData.h"

//enum {
//	kTagParentNode = 1,
//};

#pragma mark - HelloWorldLayer

#pragma mark - Constants

#define GRAIN_DROPPING_DURATION_NORMAL 0.5
#define GRAIN_DROPPING_DURATION_LEVEL_1 0.2
#define GRAIN_DROPPING_DURATION_LEVEL_2 0.1
#define GRAIN_DROPPING_DURATION_LEVEL_3 0.05
#define FAST_DROPPING_THEASHOLD_LEVEL_1 0.05
#define FAST_DROPPING_THEASHOLD_LEVEL_2 0.1
#define FAST_DROPPING_THEASHOLD_LEVEL_3 0.2
#define GRAIN_RADIUS 6
#define INITIAL_ROW_COUNT 18
#define INITIAL_COLUMN_COUNT 18

int G_Sensitivity_X, G_Sensitivity_Y, G_Sensitivity_Z;

@implementation HelloWorldLayer{
    CGSize WIN_SIZE;
    CCSpriteBatchNode *spritesheet;
    
    b2Body *allGrains[INITIAL_ROW_COUNT*INITIAL_COLUMN_COUNT];
//    b2Body *availableGrains[INITIAL_ROW_COUNT*INITIAL_COLUMN_COUNT];
    NSMutableArray *availableGrainsIndex;
    double grainDroppingDuration;
    
    CCLabelTTF *label_x, *label_y, *label_z;
    
    double acc_x, acc_y, acc_z;
    double calib_x, calib_y, calib_z;
    double diff;
    BOOL toCalibrate;
    BOOL shake_once;
    
    CCMenuItemSprite *menuItemStart, *menuItemPause, *menuItemContinue, *menuItemReset, *menuItemAudioOn, *menuItemAudioOff, *menuItemSettings;
    CCSprite *menuItemSprite_Start_Normal, *menuItemSprite_Start_Active, *menuItemSprite_Pause_Normal, *menuItemSprite_Pause_Active, *menuItemSprite_Continue_Normal, *menuItemSprite_Continue_Active, *menuItemSprite_Reset_Normal, *menuItemSprite_Reset_Active;
    BOOL paused;
    BOOL needsToResetOnStart;
    BOOL muted;
    
    int grainsCount;
    
    ScoreboardItem *sbItem_1, *sbItem_10, *sbItem_100;
    int dropCount;
    
    CCLabelBMFont *timerLabel;
    ccTime elapsedTime, elapsedTimeTS;// TS for tenth second
    int displaySeconds, displayTS;
}

+(CCScene *) scene{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

+(int)sensitivity_X{
    return G_Sensitivity_X;
}

+(void)setSensitivity_X:(int)value{
    G_Sensitivity_X = value;
}

+(int)sensitivity_Y{
    return G_Sensitivity_Y;
}

+(void)setSensitivity_Y:(int)value{
    G_Sensitivity_Y = value;
}

+(int)sensitivity_Z{
    return G_Sensitivity_Z;
}

+(void)setSensitivity_Z:(int)value{
    G_Sensitivity_Z = value;
}

#pragma mark - Lifecycle

-(id) init{
	if( (self=[super init])) {
		
		// enable events
		WIN_SIZE = [CCDirector sharedDirector].winSize;
        
        //load spritesheet
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"Textures.plist"];
        spritesheet = [CCSpriteBatchNode batchNodeWithFile:@"Textures.png"];
        [self addChild:spritesheet z:0];
        
		// init physics
		[self initPhysics];
		[self createMenu];
        [self populateGrains];
        [self initAccelerometer];
        //		self.touchEnabled = YES;
        [self initAudio];
        [self initScoreboard];
        [self initTimer];

        [self loadData];
        
        [self onReset];
        [self scheduleUpdate];
	}
	return self;
}

-(void)onExit{
    [self onPause];
    [self unscheduleUpdate];
    [super onExit];
}

-(void) dealloc{
	delete world;
	world = NULL;
	
//	delete m_debugDraw;
//	m_debugDraw = NULL;
	
	[super dealloc];
}

#pragma mark - Global Data
-(void)loadData{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    G_Sensitivity_X = [userDefaults integerForKey:kSensitivity_X];
    G_Sensitivity_Y = [userDefaults integerForKey:kSensitivity_Y];
    G_Sensitivity_Z = [userDefaults integerForKey:kSensitivity_Z];
}

#pragma mark - Draw & Update

-(void) update: (ccTime) dt{
	//It is recommended that a fixed time step is used with Box2D for stability
	//of the simulation, however, we are using a variable time step here.
	//You need to make an informed choice, the following URL is useful
	//http://gafferongames.com/game-physics/fix-your-timestep/
	
	int32 velocityIterations = 4;//8
	int32 positionIterations = 1;
	
	// Instruct the world to perform a single step of simulation. It is
	// generally best to keep the time step and iterations fixed.
	world->Step(dt, velocityIterations, positionIterations);
    [self updateTimer:dt];
}

-(void) draw{
    //	//
    //	// IMPORTANT:
    //	// This is only for debug purposes
    //	// It is recommend to disable it
    //	//
    //	[super draw];
    //
    //	ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position );
    //
    //	kmGLPushMatrix();
    //
    //	world->DrawDebugData();
    //
    //	kmGLPopMatrix();
    
//    [self drawAccelerometerDebug];
}

#pragma mark - Utility
-(b2Vec2) toMeters:(CGPoint)point{
    return b2Vec2(point.x / PTM_RATIO, point.y / PTM_RATIO);
}

-(CGPoint) toPixels:(b2Vec2)vec{
    return ccpMult(CGPointMake(vec.x, vec.y), PTM_RATIO);
}

#pragma mark - Menu

-(void) createMenu{
    //	// to avoid a retain-cycle with the menuitem and blocks
    //	__block id copy_self = self;
    
    menuItemStart = [CCMenuItemSprite
                     itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"startButtonNormal.png"]
                     selectedSprite:[CCSprite spriteWithSpriteFrameName:@"startButtonActive.png"]
                     block:^(id sender) {
                         [self onStart];
                     }];
    menuItemStart.position = ccp(120, 100);
    
    menuItemPause = [CCMenuItemSprite
                     itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"pauseButtonNormal.png"]
                     selectedSprite:[CCSprite spriteWithSpriteFrameName:@"pauseButtonActive.png"]
                     block:^(id sender) {
                         [self onPause];
                     }];
    menuItemPause.position = ccp(120, 100);
    menuItemPause.visible = NO;
    
    menuItemContinue = [CCMenuItemSprite
                     itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"continueButtonNormal.png"]
                     selectedSprite:[CCSprite spriteWithSpriteFrameName:@"continueButtonActive.png"]
                     block:^(id sender) {
                         [self onStart];
                     }];
    menuItemContinue.position = ccp(120, 100);
    menuItemContinue.visible = NO;
    
    menuItemReset = [CCMenuItemSprite
                     itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"resetButtonNormal.png"]
                     selectedSprite:[CCSprite spriteWithSpriteFrameName:@"resetButtonActive.png"]
                     block:^(id sender) {
                         [self onReset];
                     }];
    menuItemReset.position = ccp(120, 20);
    
    menuItemSettings = [CCMenuItemSprite
                        itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"settingsButtonNormal.png"]
                        selectedSprite:[CCSprite spriteWithSpriteFrameName:@"settingsButtonActive.png"]
                        block:^(id sender) {
                            [self onSettings];
                        }];
    menuItemSettings.position = ccp(120, -60);
    
    //audio menu    
    menuItemAudioOn = [CCMenuItemSprite
                     itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"audioOn.png"]
                     selectedSprite:[CCSprite spriteWithSpriteFrameName:@"audioOn.png"]
                     block:^(id sender) {
                         [self onAudio];
                     }];
    menuItemAudioOn.position = ccp(35 - WIN_SIZE.width/2, 210);
    
    menuItemAudioOff = [CCMenuItemSprite
                       itemWithNormalSprite:[CCSprite spriteWithSpriteFrameName:@"audioOff.png"]
                       selectedSprite:[CCSprite spriteWithSpriteFrameName:@"audioOff.png"]
                       block:^(id sender) {
                           [self onAudio];
                       }];
    menuItemAudioOff.position = ccp(35 - WIN_SIZE.width/2, 210);
    menuItemAudioOff.visible = NO;
    
	CCMenu *menu = [CCMenu menuWithItems: menuItemStart, menuItemPause, menuItemContinue, menuItemReset, menuItemSettings, menuItemAudioOn, menuItemAudioOff, nil];
	[self addChild:menu z:-1];
}

-(void)onStart{
    if (needsToResetOnStart) {
        [self onReset];
        needsToResetOnStart = NO;
    }
    
    paused = NO;
    [self calibrate];
    [self generateNextGrain];
    menuItemStart.visible = menuItemContinue.visible = NO;
    menuItemPause.visible = YES;
}

-(void)onPause{
    paused = YES;
    menuItemStart.visible = menuItemPause.visible = NO;
    menuItemContinue.visible = YES;
}

-(void)onReset{
//    [[CCDirector sharedDirector] replaceScene: [HelloWorldLayer scene]];
    paused = YES;
    grainDroppingDuration = GRAIN_DROPPING_DURATION_NORMAL;
    [self resetGrains];
    [self resetTimer];
    [self resetScoreboard];
    menuItemPause.visible = menuItemContinue.visible = NO;
    menuItemStart.visible = YES;
}

-(void)onFinish{
    paused = YES;
    needsToResetOnStart = YES;
    menuItemPause.visible = menuItemContinue.visible = NO;
    menuItemStart.visible = YES;
}

-(void)onSettings{
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:0.5 scene:[SettingsLayer scene] ]];
}

#pragma mark - Physics

-(void) initPhysics{
    [[GB2ShapeCache sharedShapeCache]  addShapesWithFile:@"PhysicsModel.plist"];
	
	b2Vec2 gravity;
	gravity.Set(0.0f, -10.0f);
	world = new b2World(gravity);
	
	
	// Do we want to let bodies sleep?
	world->SetAllowSleeping(true);
	
	world->SetContinuousPhysics(false);
	
//	m_debugDraw = new GLESDebugDraw( PTM_RATIO );
//	world->SetDebugDraw(m_debugDraw);
//	
//	uint32 flags = 0;
//	flags += b2Draw::e_shapeBit;
//	//		flags += b2Draw::e_jointBit;
//	//		flags += b2Draw::e_aabbBit;
//	//		flags += b2Draw::e_pairBit;
//	//		flags += b2Draw::e_centerOfMassBit;
//	m_debugDraw->SetFlags(flags);		
	
    [self setContainerShape];
}

-(void)setContainerShape{
    b2BodyDef bodyDef;
    bodyDef.position.Set((WIN_SIZE.width*0.5 - 0)/PTM_RATIO, WIN_SIZE.height*0.5/PTM_RATIO);
    b2Body* body = world->CreateBody(&bodyDef);
        
    //	CCLOG(@"Add sprite %0.2f x %02.f",p.x,p.y);
    CCPhysicsSprite *sprite = [CCPhysicsSprite spriteWithSpriteFrameName:@"bottle.png"];
	[spritesheet addChild:sprite z:0];
    
    // add the fixture definitions to the body
    [[GB2ShapeCache sharedShapeCache] addFixturesToBody:body forShapeName:@"bottle"];
    [sprite setAnchorPoint:[[GB2ShapeCache sharedShapeCache] anchorPointForShape:@"bottle"]];
	
    //    [sprite setPosition: ccp( p.x, p.y)];
	[sprite setPTMRatio:PTM_RATIO];
	[sprite setB2Body:body];
    
    //halo
    CCSprite *halo1 = [CCSprite spriteWithSpriteFrameName:@"halo.png"];
    CCSprite *halo2 = [CCSprite spriteWithSpriteFrameName:@"halo.png"];
    [spritesheet addChild:halo1 z:2];
    [spritesheet addChild:halo2 z:2];
    halo1.position = ccp(WIN_SIZE.width/2, WIN_SIZE.height/2);
    halo2.position = ccp(WIN_SIZE.width/2 - 65, WIN_SIZE.height/2 + 145);
}

-(void)populateGrains{
    availableGrainsIndex = [[NSMutableArray alloc] init];
    int index = 0;
    
    //triangle area
    for (int row = 0; row < INITIAL_COLUMN_COUNT/2; row++) {
        for (int n = 0; n < (row*2+1); n++) {
            b2Body *body = [self addNewGrain];
            allGrains[index] = body;
            index++;
        }
    }
    
    //rectangle area
    for (int row = INITIAL_COLUMN_COUNT/2; row < INITIAL_ROW_COUNT; row++) {
        for (int column = 0; column<INITIAL_COLUMN_COUNT; column++) {
            b2Body *body = [self addNewGrain];
            allGrains[index] = body;
            index ++;
        }
    }
}

-(void)resetGrains{
    [availableGrainsIndex removeAllObjects];
    int index = 0;
    
    //triangle area
    for (int row = 0; row < INITIAL_COLUMN_COUNT/2; row++) {
        for (int n = 0; n < (row*2+1); n++) {
            CGPoint point = ccp(WIN_SIZE.width/2 - (row*2+1) * GRAIN_RADIUS/2 + n * GRAIN_RADIUS, WIN_SIZE.height/2 + 20 + row * GRAIN_RADIUS);
            b2Body *body = allGrains[index];
            body->SetTransform([self toMeters:point], 0);
            body->SetLinearVelocity([self toMeters:ccp(0, 0)]);
            [availableGrainsIndex addObject:[NSNumber numberWithInt:index]];
            index++;
        }
    }
    
    //rectangle area
    for (int row = INITIAL_COLUMN_COUNT/2; row < INITIAL_ROW_COUNT; row++) {
        for (int column = 0; column<INITIAL_COLUMN_COUNT; column++) {
            CGPoint point = ccp(WIN_SIZE.width/2 - INITIAL_COLUMN_COUNT*GRAIN_RADIUS/2 + column*GRAIN_RADIUS, WIN_SIZE.height/2 + 20 + row * GRAIN_RADIUS);
            b2Body *body = allGrains[index];
            body->SetTransform([self toMeters:point], 0);
            body->SetLinearVelocity([self toMeters:ccp(0, 0)]);
            [availableGrainsIndex addObject:[NSNumber numberWithInt:index]];
            index++;
        }
    }
}

-(void) generateNextGrain{
    if (paused) {
        return;
    }
    
    if ([availableGrainsIndex count]>0) {
//        int random = arc4random() % [availableGrainsIndex count];
        NSNumber *indexNum = [availableGrainsIndex objectAtIndex:0];//[availableGrainsIndex objectAtIndex:([availableGrainsIndex count] - 1)];
        b2Body *body = allGrains[[indexNum intValue]];
        body->SetTransform([self toMeters:ccp(WIN_SIZE.width/2, WIN_SIZE.height/2 - 0*GRAIN_RADIUS)], 0);
//        b2Vec2 force = b2Vec2(0,0);
//        body->SetLinearVelocity(force);
//        world->DestroyBody(body);
        [availableGrainsIndex removeObject:indexNum];
        [self performSelector:@selector(generateNextGrain) withObject:self afterDelay:grainDroppingDuration];
        [self playDropSound];
        [self countDrop];
    }
    else{
        [self onFinish];
    }
}

-(b2Body *) addNewGrain{
    CCPhysicsSprite *sprite = [CCPhysicsSprite spriteWithSpriteFrameName:@"grain.png"];
	[spritesheet addChild:sprite z:1];
	
	b2BodyDef bodyDef;
	bodyDef.type = b2_dynamicBody;
//    bodyDef.position.Set(p.x/PTM_RATIO, p.y/PTM_RATIO);
	b2Body *body = world->CreateBody(&bodyDef);
    
    // add the fixture definitions to the body
    [[GB2ShapeCache sharedShapeCache] addFixturesToBody:body forShapeName:@"grain"];
    [sprite setAnchorPoint:[[GB2ShapeCache sharedShapeCache] anchorPointForShape:@"grain"]];
	
    //    [sprite setPosition: ccp( p.x, p.y)];
	[sprite setPTMRatio:PTM_RATIO];
	[sprite setB2Body:body];
    
    return body;
}

#pragma mark - Touch

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
//	//Add a new body/atlas sprite at the touched location
//	for( UITouch *touch in touches ) {
//		CGPoint location = [touch locationInView: [touch view]];
//		
//		location = [[CCDirector sharedDirector] convertToGL: location];
//		
//		[self addNewSpriteAtPosition: location];
//	}
}

#pragma mark - Accelerometer
-(void)initAccelerometer{
    self.accelerometerEnabled = YES;
    [[UIAccelerometer sharedAccelerometer] setUpdateInterval:0.05];
    shake_once = false;
}

-(void)initDebugText{
    //    label_x = [CCLabelTTF labelWithString:@"X value" fontName:@"Arial" fontSize:16];
    //    label_y = [CCLabelTTF labelWithString:@"Y value" fontName:@"Marker Felt" fontSize:16];
    //    label_z = [CCLabelTTF labelWithString:@"Z value" fontName:@"Marker Felt" fontSize:16];
    //
    //    [self addChild:label_x z:0];
    //    [self addChild:label_y z:0];
    //    [self addChild:label_z z:0];
    //    [label_x setColor:ccc3(0,0,255)];
    //
    //    label_x.position = ccp( 100, WIN_SIZE.height-50);
    //    label_y.position = ccp( 200, WIN_SIZE.height-50);
    //    label_z.position = ccp( 300, WIN_SIZE.height-50);
}

-(void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration{
//    CCLOG(@"acceleration:x:%f, y:%f, z:%f", acceleration.x, acceleration.y, acceleration.z);
//    [label_x setString:[NSString stringWithFormat:@"%0.4f",acceleration.x]];
//    [label_y setString:[NSString stringWithFormat:@"%0.4f",acceleration.y]];
//    [label_z setString:[NSString stringWithFormat:@"%0.4f",acceleration.z]];
    
    acc_x = acceleration.x;
    acc_y = acceleration.y;
    acc_z = acceleration.z;
    
    if (toCalibrate) {
        calib_x = acc_x;
        calib_y = acc_y;
        calib_z = acc_z;
        toCalibrate = NO;
    }
    
    [self adjustDropping:acc_x y:acc_y z:acc_z];
}

-(void)calibrate{
    toCalibrate = YES;
}

-(void)adjustDropping:(double)x y:(double)y z:(double)z{
    if (paused) {
        return;
    }

//    diff  = sqrt(pow((x - calib_x), 2) + pow((y - calib_y), 2) + pow((z - calib_z), 2));
    
    if (ABS(x - calib_x) * G_Sensitivity_X > FAST_DROPPING_THEASHOLD_LEVEL_3
        || ABS(y - calib_y) * G_Sensitivity_Y > FAST_DROPPING_THEASHOLD_LEVEL_3
        || ABS(z - calib_z) * G_Sensitivity_Z > FAST_DROPPING_THEASHOLD_LEVEL_3) {
        grainDroppingDuration = GRAIN_DROPPING_DURATION_LEVEL_3;
    }
    else if (ABS(x - calib_x) * G_Sensitivity_X > FAST_DROPPING_THEASHOLD_LEVEL_2
        || ABS(y - calib_y) * G_Sensitivity_Y > FAST_DROPPING_THEASHOLD_LEVEL_2
        || ABS(z - calib_z) * G_Sensitivity_Z > FAST_DROPPING_THEASHOLD_LEVEL_2) {
        grainDroppingDuration = GRAIN_DROPPING_DURATION_LEVEL_2;
    }
    else if (ABS(x - calib_x) * G_Sensitivity_X > FAST_DROPPING_THEASHOLD_LEVEL_1
             || ABS(y - calib_y) * G_Sensitivity_Y > FAST_DROPPING_THEASHOLD_LEVEL_1
             || ABS(z - calib_z) * G_Sensitivity_Z > FAST_DROPPING_THEASHOLD_LEVEL_1) {
        grainDroppingDuration = GRAIN_DROPPING_DURATION_LEVEL_1;
    }
    else{
        grainDroppingDuration = GRAIN_DROPPING_DURATION_NORMAL;
    }
}

-(void)drawAccelerometerDebug{
    glLineWidth( 5.0f );
    
    //realtime reading
	ccDrawColor4B(255,0,0,255);
    ccDrawLine(ccp(WIN_SIZE.width/2, WIN_SIZE.height-50), ccp(WIN_SIZE.width/2 + acc_x * 100, WIN_SIZE.height-50));
    ccDrawColor4B(0,255,0,255);
    ccDrawLine(ccp(WIN_SIZE.width/2, WIN_SIZE.height-60), ccp(WIN_SIZE.width/2 + acc_y * 100, WIN_SIZE.height-60));
    ccDrawColor4B(0,0,255,255);
    ccDrawLine(ccp(WIN_SIZE.width/2, WIN_SIZE.height-70), ccp(WIN_SIZE.width/2 + acc_z * 100, WIN_SIZE.height-70));
    
    //difference from calibration
    ccDrawColor4B(255,0,0,255);
    ccDrawLine(ccp(WIN_SIZE.width/2, 70), ccp(WIN_SIZE.width/2 + (acc_x - calib_x) * 100, 70));
    ccDrawColor4B(0,255,0,255);
    ccDrawLine(ccp(WIN_SIZE.width/2, 60), ccp(WIN_SIZE.width/2 + (acc_y - calib_y) * 100, 60));
    ccDrawColor4B(0,0,255,255);
    ccDrawLine(ccp(WIN_SIZE.width/2, 50), ccp(WIN_SIZE.width/2 + (acc_z - calib_z) * 100, 50));
    
    ccDrawColor4B(0,255,255,255);
    ccDrawLine(ccp(WIN_SIZE.width/2, 30), ccp(WIN_SIZE.width/2 + diff * 100, 30));
}

#pragma mark - Audio
-(void)initAudio{
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"drop_sfx.wav"];
}

-(void)playDropSound{
    if (muted) {
        return;
    }
    [[SimpleAudioEngine sharedEngine] playEffect:@"drop_sfx.wav"];
}

-(void)onAudio{
    if (!muted) {
        menuItemAudioOn.visible = NO;
        menuItemAudioOff.visible = YES;
    }
    else{
        menuItemAudioOn.visible = YES;
        menuItemAudioOff.visible = NO;
    }
    muted = !muted;
}

#pragma mark - Scoreboard
-(void)initScoreboard{
    sbItem_1 = [[ScoreboardItem alloc] initWithSpritesheet:spritesheet Number:0];
    sbItem_1.position = ccp(WIN_SIZE.width/2+60, 50);
    
    sbItem_10 = [[ScoreboardItem alloc] initWithSpritesheet:spritesheet Number:0];
    sbItem_10.position = ccp(WIN_SIZE.width/2+0, 50);
    
    sbItem_100 = [[ScoreboardItem alloc] initWithSpritesheet:spritesheet Number:0];
    sbItem_100.position = ccp(WIN_SIZE.width/2-60, 50);
}

-(void)resetScoreboard{
    dropCount = 0;
    [sbItem_1 setNumber:0];
    [sbItem_10 setNumber:0];
    [sbItem_100 setNumber:0];
}

-(void)countDrop{
    dropCount++;
    [sbItem_1 setNumber:dropCount % 10];
    [sbItem_10 setNumber:(int)(dropCount/10) % 10];
    [sbItem_100 setNumber:(int)(dropCount/100) % 10];
}

#pragma mark - Countdown Timer
-(void)initTimer{
    timerLabel = [CCLabelBMFont labelWithString:@"00:00.0" fntFile:@"BMFont.fnt"];
    timerLabel.alignment = kCCTextAlignmentLeft;
    timerLabel.anchorPoint = ccp(0,0.7f);
    timerLabel.position = ccp(10, WIN_SIZE.height/2 + 180);
    [self addChild:timerLabel z:0];
    
    [self resetTimer];
}

-(void)resetTimer{
    [timerLabel setString:@"00:00.0"];
    elapsedTime = 0;
    elapsedTimeTS = 0;
    displaySeconds = 0;
    displayTS = 0;
}

-(void)updateTimer:(ccTime)dt{
    if (paused) {
        return;
    }
    elapsedTime += dt;
    elapsedTimeTS += dt*10;
    if (displayTS < (int)elapsedTimeTS) {
        displayTS = (int)elapsedTimeTS;
        if (displaySeconds<(int)elapsedTime) {
            displaySeconds = (int)elapsedTime;
        }
        
        [timerLabel setString:[NSString stringWithFormat:@"%.2d:%.2d.%d", (int)displaySeconds/60, (int)displaySeconds % 60, (int)displayTS % 10]];
        
//        NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];//实例化一个NSDateFormatter对象
//        [dateFormat setDateFormat:@"HH:mm:ss"];//设定时间格式,这里可以设置成自己需要的格式
//        NSString *currentDateStr = [dateFormat stringFromDate:[NSDate date]];        
//        [timerLabel setString:[NSString stringWithFormat:@"%.2d:%.2d.%d  %@", (int)displaySeconds/60, (int)displaySeconds % 60, (int)displayTS % 10, currentDateStr]];
    }
}

@end
