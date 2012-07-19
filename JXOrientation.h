//
//  JXOrientation.h
//  orientations
//
//  Created by Jérôme Alves on 09/07/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JXOrientation : NSObject

- (void) removeActionForSelector:(SEL)aSelector;

@end


@interface UIView (JXOrientation)

- (id) portrait;
- (id) portraitStraight;
- (id) portraitUpsideDown;
- (id) landscape;
- (id) landscapeLeft;
- (id) landscapeRight;

@end


@interface UIViewController (JXOrientation)

@end
