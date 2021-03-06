//
//  Gameplay.m
//  PeevedPenguins
//
//  Created by Robert Eastmond on 6/28/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Gameplay.h"
#import "CCPhysics+ObjectiveChipmunk.h"
#import "Seal.h"

@implementation Gameplay{
    CCPhysicsNode * _physicsNode;
    CCNode * _catapultArm;
    CCNode * _levelNode;
    CCNode * _contentNode;
    CCNode * _pullbackNode;
    CCNode * _mouseJointNode;
    CCPhysicsJoint * _mouseJoint;
    Penguin * _currentPenguin;
    CCPhysicsJoint * _penguinCatapultJoint;
    CCAction * _followPenguin;
    int numOfSeals;
    int currentLevel;

}
//constant minimum speed
static const float MIN_SPEED = 5.f;

//Is called when the ccb file has completed loading
-(void) didLoadFromCCB{
    
    //sign up as the collision delegate of the physics node
    _physicsNode.collisionDelegate = self;
    
    //tell the scene to accept touches
    self.userInteractionEnabled = TRUE;
    
    //load the first level
    CCScene *level = [CCBReader loadAsScene:@"Levels/Level2"];
    [_levelNode addChild:level];
    currentLevel = 1;
    
    numOfSeals =[self countSeals];
    //CCLOG(@"SealCount = %d",sealcount);
    //CCLOG(@"ChildCount = %d",childCount);
    //visualize the physics bodies and joints
    //_physicsNode.debugDraw = TRUE;
    
    //code to prevent objects from colliding with invisible nodes
    _pullbackNode.physicsBody.collisionMask = @[];
    _mouseJointNode.physicsBody.collisionMask = @[];
    
}
//method to load the next level when the previous level is completed
-(void)LoadNextLevel{
    //create the name of the current and new level node
    
    NSString *oldlevelPath =  [NSString stringWithFormat:@"Levels/Level%d",currentLevel];
    NSString *newlevelPath =  [NSString stringWithFormat:@"Levels/Level%d",++currentLevel];
    
    //create temporary levels to remove and add
    CCScene *oldLevel = [CCBReader loadAsScene:oldlevelPath];
    CCScene *newLevel = [CCBReader loadAsScene:newlevelPath];
    //remove the current level node
    [_levelNode removeChild:oldLevel cleanup:YES];
    //add the new level node
    [_levelNode addChild:newLevel];
    //count the new seals
    numOfSeals  = [self countSeals];
    
}
-(int)countSeals{
    //Just some code to count how many seals there are on the level, Could this be its own method to check for the number of seals left, assign points and end the level?
    CCLOG(@"There are %lu children in the _leveNode", (unsigned long)_levelNode.children.count);
    CCScene *level = _levelNode.children[0];
    int sealcount = 0;
    //int childCount = 0;
    for (id levelChild in level.children) {
        
    
        if ([levelChild isKindOfClass:[CCNode class]]) {
            CCNode *node = levelChild;
            
            for(id NodeChild in node.children){
                if ([NodeChild isKindOfClass:[Seal class]]) {
                    sealcount++;
                    CCLOG(@"SealCount = %d",sealcount);
                }
                NSString *className = NSStringFromClass([NodeChild class]);
                CCLOG(@"Your object is a %@",className);
                
                //childCount++;
            }
            
        }
    }
    return sealcount;
}



//Update method is called every frame
-(void)update:(CCTime)delta{
    //if (numOfSeals > 0) {
        
    
        //check to see if the current penguin has been launched before checking speed and position
        if (_currentPenguin.launched) {
        
            //if speed is below the minimum, assume the penguin throw is over
            if(ccpLength(_currentPenguin.physicsBody.velocity)<MIN_SPEED){
                
                //call next attempt
                [self nextAttempt];
                return;
            }
    
            int xMin = _currentPenguin.boundingBox.origin.x;
    
            if (xMin <  self.boundingBox.origin.x) {
                [self nextAttempt];
                return;
            }
    
            int xMax = xMin + _currentPenguin.boundingBox.size.width;
    
            if (xMax > (self.boundingBox.origin.x + self.boundingBox.size.width)) {
                [self nextAttempt];
                return;
            }
        
        }
    //}
    //else{
    //    [self LoadNextLevel];
    //}
}

//nextAttempt resets the camera back to the left of the level
-(void)nextAttempt{
    
    //release the pointer to the current penguin
    _currentPenguin= nil;
    
    //stop the _followPenguin action on the content node
    [_contentNode stopAction:_followPenguin];
    
    //create a new action to scroll back to the catapult
    CCActionMoveTo * actionMoveTo = [CCActionMoveTo actionWithDuration:1.f position:ccp(0,0)];
    [_contentNode runAction:actionMoveTo];
}

//called on every touch of the scene
-(void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
    //Testing just to launch the penguin
    //[self launchPenguin];
    
    CGPoint touchLocation = [touch locationInNode:_contentNode];
    
    //Start dragging the catapult arm when the touch occurs on the catapult arm
    if(CGRectContainsPoint([_catapultArm boundingBox], touchLocation)){
        
        //create a penguin from the ccb file
        _currentPenguin = (Penguin *)[CCBReader load:@"Penguin"];
        
        //initially position the penguin on the scoop at 34, 138.  Try to avoid magic numbers by declaring these starting positions as variables
        CGPoint penguinPosition = [_catapultArm convertToWorldSpace:ccp(34,138)];
        
        //transform the world position to the node space to which the penguin will be added
        _currentPenguin.position = [_physicsNode convertToNodeSpace:penguinPosition];
        
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
        
        //set the launched property of the current penguin to true
        _currentPenguin.launched= TRUE;
        
        //follow the flying penguin
        _followPenguin = [CCActionFollow actionWithTarget:_currentPenguin worldBoundary:self.boundingBox];
        [_contentNode runAction:_followPenguin];
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

- (void)sealRemoved:(CCNode *)seal {
    
    //load particle effect
    CCParticleSystem * explosion = (CCParticleSystem *)[CCBReader load:@"SealExplosion"];
    
    //make the particle effect clean itself up, once it is completed
    explosion.autoRemoveOnFinish = TRUE;
    
    //place the particle effect on the seals position
    explosion.position = seal.position;
    
    //add the explosion onto the same node that the seal is on (thats why it is seal.parent)
    [seal.parent addChild:explosion];
    
    //remove the destroyed seal
    [seal removeFromParent];
    numOfSeals--;
}

-(void)ccPhysicsCollisionPostSolve:(CCPhysicsCollisionPair *)pair seal:(CCNode *)nodeA wildcard:(CCNode *)nodeB{
    //CCLOG(@"Something collided with a seal");
    
    float energy = [pair totalKineticEnergy];
    
    //if energy is large enough, remove the seal
    if (energy > 5000.f) {
        [[_physicsNode space] addPostStepBlock:^{
            [self sealRemoved:nodeA];
        }key:nodeA];
    }
}


@end
