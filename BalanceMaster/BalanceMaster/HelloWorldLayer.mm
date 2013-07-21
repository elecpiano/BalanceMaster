//
//  HelloWorldLayer.mm
//  BalanceMaster
//
//  Created by Lee Jason on 13-7-20.
//  Copyright namiapps 2013年. All rights reserved.
//

// Import the interfaces
#import "HelloWorldLayer.h"

// Not included in "cocos2d.h"
#import "CCPhysicsSprite.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"

#import "GB2ShapeCache.h"

enum {
	kTagParentNode = 1,
};


#pragma mark - HelloWorldLayer

#pragma mark - Constants

//#define GRAIN_COUNT 100
#define GRAIN_DROPPING_DURATION_NORMAL 0.5
#define GRAIN_RADIUS 6
#define INITIAL_ROW_COUNT 16
#define INITIAL_COLUMN_COUNT 16
#define FAST_DROPPING_THEASHOLD 0.2

//@interface HelloWorldLayer()
//-(void) initPhysics;
//-(b2Body *) addNewSpriteAtPosition:(CGPoint)p;
//-(void) createMenu;
//@end

@implementation HelloWorldLayer{
    CGSize WIN_SIZE;
    CCSpriteBatchNode *spritesheet;
    
    b2Body *availableGrains[INITIAL_ROW_COUNT*INITIAL_COLUMN_COUNT];
    NSMutableArray *availableGrainsIndex;
    double grainDroppingDuration;
    
    CCLabelTTF *label_x, *label_y, *label_z;
    
    double acc_x, acc_y, acc_z;
    double calib_x, calib_y, calib_z;
    double diff;
    BOOL toCalibrate;
    BOOL shake_once;
    
    CCMenuItemLabel *menuItemStart;
    CCMenuItemLabel *menuItemReset;
    BOOL paused;
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
		
		// create reset button
		[self createMenu];

        [self populateGrains];
        
        [self initAccelerometer];
        //		self.touchEnabled = YES;
		
		[self scheduleUpdate];
        
        grainDroppingDuration = GRAIN_DROPPING_DURATION_NORMAL;
        paused = YES;
	}
	return self;
}

-(void) dealloc{
	delete world;
	world = NULL;
	
//	delete m_debugDraw;
//	m_debugDraw = NULL;
	
	[super dealloc];
}

#pragma mark - Draw & Update

-(void) update: (ccTime) dt{
	//It is recommended that a fixed time step is used with Box2D for stability
	//of the simulation, however, we are using a variable time step here.
	//You need to make an informed choice, the following URL is useful
	//http://gafferongames.com/game-physics/fix-your-timestep/
	
	int32 velocityIterations = 8;
	int32 positionIterations = 1;
	
	// Instruct the world to perform a single step of simulation. It is
	// generally best to keep the time step and iterations fixed.
	world->Step(dt, velocityIterations, positionIterations);
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

#pragma mark - Menu

-(void) createMenu{
	[CCMenuItemFont setFontSize:36];
    
    // Start Button
    menuItemStart = [CCMenuItemFont itemWithString:@"Start" block:^(id sender){
		[self onStart];
	}];
    
	// Reset Button
    menuItemReset = [CCMenuItemFont itemWithString:@"Reset" block:^(id sender){
		[self onReset];
	}];

	// to avoid a retain-cycle with the menuitem and blocks
	__block id copy_self = self;
	
	CCMenu *menu = [CCMenu menuWithItems: menuItemStart, menuItemReset, nil];
	
	[menu alignItemsVertically];
	[menu setPosition:ccp( WIN_SIZE.width - 60, WIN_SIZE.height/2)];
	
	[self addChild: menu z:-1];	
}

-(void)onStart{
    if (paused) {
        paused = NO;
        [self calibrate];
        [self generateNextGrain];
        [menuItemStart setString:@"Pause"];
    }
    else
    {
        [menuItemStart setString:@"Continue"];
        paused = YES;
    }
}

-(void)onReset{
    [[CCDirector sharedDirector] replaceScene: [HelloWorldLayer scene]];
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
    bodyDef.position.Set(WIN_SIZE.width*0.5/PTM_RATIO, WIN_SIZE.height*0.5/PTM_RATIO);
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
}

-(void)populateGrains{
    availableGrainsIndex = [[NSMutableArray alloc] init];
    for (int row = 0; row<INITIAL_ROW_COUNT; row++) {
        for (int column = 0; column<INITIAL_COLUMN_COUNT; column++) {
            CGPoint point = ccp(WIN_SIZE.width/2 - INITIAL_COLUMN_COUNT*GRAIN_RADIUS/2 + column*GRAIN_RADIUS, WIN_SIZE.height/2 + 150 - row*GRAIN_RADIUS);
            b2Body *body = [self addNewSpriteAtPosition:point];
            int index = row * INITIAL_ROW_COUNT + column;
            availableGrains[index] = body;
            [availableGrainsIndex addObject:[NSNumber numberWithInt:index]];
        } 
    }
}

-(void) generateNextGrain{
    if (paused) {
        return;
    }
    
    if ([availableGrainsIndex count]>0) {
//        int random = arc4random() % [availableGrainsIndex count];
        int random = [availableGrainsIndex count] -1;
        NSNumber *indexNum = [availableGrainsIndex objectAtIndex:random];
        b2Body *body = availableGrains[[indexNum intValue]];
        world->DestroyBody(body);
        [availableGrainsIndex removeObjectAtIndex:random];
        [self addNewSpriteAtPosition:ccp(WIN_SIZE.width/2, WIN_SIZE.height/2 - GRAIN_RADIUS)];
        [self performSelector:@selector(generateNextGrain) withObject:self afterDelay:grainDroppingDuration];
    }
}

int droppedGrainCount = 0;
-(void) generateNextGrain2{
    
    if (droppedGrainCount<INITIAL_ROW_COUNT*INITIAL_COLUMN_COUNT) {
        [self addNewSpriteAtPosition:ccp(WIN_SIZE.width/2, WIN_SIZE.height/2 - GRAIN_RADIUS)];
        [self performSelector:@selector(generateNextGrain) withObject:self afterDelay:grainDroppingDuration];
        droppedGrainCount++;
    }
}

-(b2Body *) addNewSpriteAtPosition:(CGPoint)p{
    //	CCLOG(@"Add sprite %0.2f x %02.f",p.x,p.y);
    CCPhysicsSprite *sprite = [CCPhysicsSprite spriteWithSpriteFrameName:@"grain.png"];
	[spritesheet addChild:sprite z:1];
	
	b2BodyDef bodyDef;
	bodyDef.type = b2_dynamicBody;
	bodyDef.position.Set(p.x/PTM_RATIO, p.y/PTM_RATIO);
//    bodyDef.userData = sprite;
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

    diff  = sqrt(pow((x - calib_x), 2) + pow((y - calib_y), 2) + pow((z - calib_z), 2));
    
    if (ABS(x - calib_x) > FAST_DROPPING_THEASHOLD
        || ABS(y - calib_y) > FAST_DROPPING_THEASHOLD
        || ABS(z - calib_z) > FAST_DROPPING_THEASHOLD) {
        grainDroppingDuration = 0.1;
    }
    else{
        grainDroppingDuration = GRAIN_DROPPING_DURATION_NORMAL;
    }
}

#pragma mark - Utility
-(b2Vec2) toMeters:(CGPoint)point{
    return b2Vec2(point.x / PTM_RATIO, point.y / PTM_RATIO);
}

-(CGPoint) toPixels:(b2Vec2)vec{
    return ccpMult(CGPointMake(vec.x, vec.y), PTM_RATIO);
}

@end
