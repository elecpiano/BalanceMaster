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

#define GRAIN_COUNT 225
#define GRAIN_GENERATING_DURATION 0.3
#define GRAIN_RADIUS 6

@interface HelloWorldLayer()
-(void) initPhysics;
-(b2Body *) addNewSpriteAtPosition:(CGPoint)p;
-(void) createMenu;
@end

@implementation HelloWorldLayer{
    CGSize WIN_SIZE;
    CCSpriteBatchNode *spritesheet;
    b2Body *availableGrains[GRAIN_COUNT];
    NSMutableArray *availableGrainsIndex;
}

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

-(id) init
{
	if( (self=[super init])) {
		
		// enable events
		
		self.touchEnabled = YES;
		self.accelerometerEnabled = YES;
		WIN_SIZE = [CCDirector sharedDirector].winSize;
        
        //load spritesheet
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"Textures.plist"];
        spritesheet = [CCSpriteBatchNode batchNodeWithFile:@"Textures.png"];
        [self addChild:spritesheet z:0];
        
		// init physics
		[self initPhysics];
		
		// create reset button
		[self createMenu];

        [self populateSandGrains];
        [self generateNextGrain];
		
		CCLabelTTF *label = [CCLabelTTF labelWithString:@"Tap screen" fontName:@"Marker Felt" fontSize:32];
		[self addChild:label z:0];
		[label setColor:ccc3(0,0,255)];
		label.position = ccp( WIN_SIZE.width/2, WIN_SIZE.height-50);
		
		[self scheduleUpdate];
	}
	return self;
}

-(void) dealloc
{
	delete world;
	world = NULL;
	
	delete m_debugDraw;
	m_debugDraw = NULL;
	
	[super dealloc];
}	

-(void) createMenu
{
	// Default font size will be 22 points.
	[CCMenuItemFont setFontSize:22];
	
	// Reset Button
	CCMenuItemLabel *reset = [CCMenuItemFont itemWithString:@"Reset" block:^(id sender){
		[[CCDirector sharedDirector] replaceScene: [HelloWorldLayer scene]];
	}];

	// to avoid a retain-cycle with the menuitem and blocks
	__block id copy_self = self;
	
	CCMenu *menu = [CCMenu menuWithItems: reset, nil];
	
	[menu alignItemsVertically];
	[menu setPosition:ccp( WIN_SIZE.width/2, WIN_SIZE.height - 20)];
	
	
	[self addChild: menu z:-1];	
}

-(void) initPhysics
{
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
    
    return;
    
    
    b2EdgeShape shape;
    
    shape.Set([self toMeters:ccp(0, 480)], [self toMeters:ccp(160,480)]);
    body->CreateFixture(&shape,0);
    
    shape.Set([self toMeters:ccp(160, 480)], [self toMeters:ccp(160,380)]);
    body->CreateFixture(&shape,0);
    
    shape.Set([self toMeters:ccp(160, 380)], [self toMeters:ccp(100,330)]);
    body->CreateFixture(&shape,0);
    
    shape.Set([self toMeters:ccp(100, 330)], [self toMeters:ccp(160,280)]);
    body->CreateFixture(&shape,0);
    
    shape.Set([self toMeters:ccp(160, 280)], [self toMeters:ccp(160,180)]);
    body->CreateFixture(&shape,0);
    
    shape.Set([self toMeters:ccp(160, 180)], [self toMeters:ccp(0,180)]);
    body->CreateFixture(&shape,0);
    
    shape.Set([self toMeters:ccp(0, 180)], [self toMeters:ccp(0,280)]);
    body->CreateFixture(&shape,0);
    
    shape.Set([self toMeters:ccp(0, 280)], [self toMeters:ccp(60,330)]);
    body->CreateFixture(&shape,0);
    
    shape.Set([self toMeters:ccp(60, 330)], [self toMeters:ccp(0,380)]);
    body->CreateFixture(&shape,0);
    
    shape.Set([self toMeters:ccp(0, 380)], [self toMeters:ccp(0,480)]);
    body->CreateFixture(&shape,0);
}

-(void) draw
{
	//
	// IMPORTANT:
	// This is only for debug purposes
	// It is recommend to disable it
	//
	[super draw];
	
	ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position );
	
	kmGLPushMatrix();
	
	world->DrawDebugData();	
	
	kmGLPopMatrix();
}

-(void)populateSandGrains{
    availableGrainsIndex = [[NSMutableArray alloc] init];
    for (int row = 0; row<15; row++) {
        for (int column = 0; column<15; column++) {
            CGPoint point = ccp(WIN_SIZE.width/2 - 50 + column*GRAIN_RADIUS, WIN_SIZE.height/2 + 120 - row*GRAIN_RADIUS);
            b2Body *body = [self addNewSpriteAtPosition:point];
            int index = row * 15 + column;
            availableGrains[index] = body;
            [availableGrainsIndex addObject:[NSNumber numberWithInt:index]];
        } 
    }
}

-(void) generateNextGrain{
    
    if ([availableGrainsIndex count]>0) {
//        int random = arc4random() % [availableGrainsIndex count];
        int random = [availableGrainsIndex count] -1;
        NSNumber *indexNum = [availableGrainsIndex objectAtIndex:random];
        b2Body *body = availableGrains[[indexNum intValue]];
        world->DestroyBody(body);
        [availableGrainsIndex removeObjectAtIndex:random];
        [self addNewSpriteAtPosition:ccp(160, 230)];
        [self performSelector:@selector(generateNextGrain) withObject:self afterDelay:GRAIN_GENERATING_DURATION];
    }
}

-(b2Body *) addNewSpriteAtPosition:(CGPoint)p
{
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

-(void) update: (ccTime) dt
{
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

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	//Add a new body/atlas sprite at the touched location
	for( UITouch *touch in touches ) {
		CGPoint location = [touch locationInView: [touch view]];
		
		location = [[CCDirector sharedDirector] convertToGL: location];
		
		[self addNewSpriteAtPosition: location];
	}
}

#pragma mark GameKit delegate

-(void) achievementViewControllerDidFinish:(GKAchievementViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissModalViewControllerAnimated:YES];
}

-(void) leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissModalViewControllerAnimated:YES];
}

/**************** Utility ***************/
-(b2Vec2) toMeters:(CGPoint)point
{
    return b2Vec2(point.x / PTM_RATIO, point.y / PTM_RATIO);
}
-(CGPoint) toPixels:(b2Vec2)vec
{
    return ccpMult(CGPointMake(vec.x, vec.y), PTM_RATIO);
}


@end
