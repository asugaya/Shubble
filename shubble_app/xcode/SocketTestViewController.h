//
//  SocketTestViewController.h
//  SocketTest
//
//  Created by Travis Wyatt on 9/23/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AsyncSocket.h"


@interface SocketTestViewController  :NSObject{
	AsyncSocket *socket;
    int timeBetweenKnocks;
}

- (void)connectToShubble;
- (id)init;
- (id)initWithTime:(int)time;

@end

