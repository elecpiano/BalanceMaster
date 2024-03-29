//
//  HelloWorldLayer.h
//  BalanceMaster
//
//  Created by Lee Jason on 13-7-20.
//  Copyright namiapps 2013年. All rights reserved.
//


#import <GameKit/GameKit.h>

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
#import "Box2D.h"
#import "GLES-Render.h"

//Pixel to metres ratio. Box2D uses metres as the unit for measurement.
//This ratio defines how many pixels correspond to 1 Box2D "metre"
//Box2D is optimized for objects of 1x1 metre therefore it makes sense
//to define the ratio so that your most common object type is 1x1 metre.
#define PTM_RATIO 16

// HelloWorldLayer
@interface HelloWorldLayer : CCLayer
{
//	CCTexture2D *spriteTexture_;	// weak ref
	b2World* world;					// strong ref
	GLESDebugDraw *m_debugDraw;		// strong ref
}

+(int)sensitivity_X;
+(void)setSensitivity_X:(int)value;

+(int)sensitivity_Y;
+(void)setSensitivity_Y:(int)value;

+(int)sensitivity_Z;
+(void)setSensitivity_Z:(int)value;

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

@end
