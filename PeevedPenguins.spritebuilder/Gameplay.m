//
//  Gameplay.m
//  PeevedPenguins
//
//  Created by Robert Eastmond on 6/28/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Gameplay.h"

@implementation Gameplay{
    CCPhysicsNode * _physicsNode;
    CCNode * _catapultArm;
    CCNode * _levelNode;
    CCNode * _contentNode;
    CCNode * _pullbackNode;
    
    

}
//Is called when the ccb file has completed loading
-(void) didLoadFromCCB{
    //tell the scene to accept touches
    self.userInteractionEnabled = TRUE;
    
    //load the first level
    CCScene *level = [CCBReader loadAsScene:@"Levels/Level1"];
    [_levelNode addChild:level];
    
    //visualize the physics bodies and joints
    //_physicsNode.debugDraw = TRUE;
    
    //code to prevent objects from colliding with invisible nodes
    _pullbackNode.physicsBody.collisionMask = @[];
    
    
}

//called on every touch of the scene
-(void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
    [self launchPenguin];
}
-(void)retry{
    //reload the level
    [[CCDirector sharedDirector]replaceScene:[CCBReader loadAsScene:@"Gameplay"]];
}
-(void)launchPenguin{
    //loads the Penguin.ccb we set up in Spritebuilder
    CCNode * penguin = [CCBReader load:@"Penguin"];
    //position the penguin at the bowl of the catapult arm
    penguin.position = ccpAdd(_catapultArm.position, ccp(16, 50));
    
    //add the penguin to the physicsNode of this scene because it has physics enabled
    [_physicsNode addChild:penguin];
    
    //manually create and apply a force to launch the penguin
    CGPoint launchDirection = ccp(1,0);
    CGPoint force = ccpMult(launchDirection, 8000);
    
    [penguin.physicsBody applyForce:force];
    //set up the camera to follow the penguin after it launches
    //ensure the followed object is in the visible area when starting
    self.position = ccp(0,0);
    CCActionFollow *follow = [CCActionFollow actionWithTarget:penguin worldBoundary:self.boundingBox];
    [_contentNode runAction:follow];
}
@end
