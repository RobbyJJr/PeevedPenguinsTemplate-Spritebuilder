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
    CCNode * _mouseJointNode;
    CCPhysicsJoint * _mouseJoint;
    CCNode * _currentPenguin;
    CCPhysicsJoint * _penguinCatapultJoint;
    
    

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
    _mouseJointNode.physicsBody.collisionMask = @[];
    
}

//called on every touch of the scene
-(void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
    //Testing just to launch the penguin
    //[self launchPenguin];
    
    CGPoint touchLocation = [touch locationInNode:_contentNode];
    
    //Start dragging the catapult arm when the touch occurs on the catapult arm
    if(CGRectContainsPoint([_catapultArm boundingBox], touchLocation)){
        
        //create a penguin from the ccb file
        _currentPenguin = [CCBReader load:@"Penguin"];
        
        //initially position the penguin on the scoop at 34, 138.  Try to avoid magic numbers by declaring these starting positions as variables
        _currentPenguin.position = [_physicsNode convertToNodeSpace:ccp(34,138)];
        
        //add the penguin to the physics world
        [_physicsNode addChild:_currentPenguin];
        
        //dont let the penguin rotate in the scoop
        _currentPenguin.physicsBody.allowsRotation = FALSE;
        
        //create a joint between the scoop and the penguin to prevent the penguin from falling before the arm is released
        _penguinCatapultJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:_currentPenguin.physicsBody bodyB:_catapultArm.physicsBody anchorA:_currentPenguin.anchorPointInPoints];
        
        //move the mouseJointNode to the touch position
        _mouseJointNode.position =touchLocation;
        
        //setup a spring joint between the mouseJointNode and the catapultArm
        _mouseJoint = [CCPhysicsJoint connectedSpringJointWithBodyA:_mouseJointNode.physicsBody bodyB:_catapultArm.physicsBody anchorA:ccp(0,0) anchorB:ccp(34,138) restLength:0.f stiffness:3000.f damping:150.f];
        
        
    }
}

-(void)touchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
    //whenever the touch moves, update the position of the _mouseJointNode to the touch location
    CGPoint touchLocation = [touch locationInNode:_contentNode];
    
    _mouseJointNode.position= touchLocation;
}

-(void)releaseCatapult{
    if (_mouseJoint != nil) {
        //release the joint and lets the catapult arm snap back
        [_mouseJoint invalidate];
        _mouseJoint = nil;
        
        //releases the joint and lets the penguin fly
        [_penguinCatapultJoint invalidate];
        _penguinCatapultJoint = nil;
        
        //after the catapult arm snaps, rotation is ok
        _currentPenguin.physicsBody.allowsRotation = TRUE;
        
        //follow the flying penguin
        CCActionFollow *follow = [CCActionFollow actionWithTarget:_currentPenguin worldBoundary:self.boundingBox];
        [_contentNode runAction:follow];
    }
}

-(void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
    //when the touch ends call release catapult
    [self releaseCatapult];
}

-(void)touchCancelled:(UITouch *)touch withEvent:(UIEvent *)event{
    //when the touch goes off the screen release the catapult arm
    [self releaseCatapult];
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
