//
//  JXOrientation.m
//
//  Created by Jérôme Alves on 09/07/12.
//  Copyright (c) 2012 Jérôme Alves. All rights reserved.
//

#import "JXOrientation.h"
#import <objc/runtime.h>

NSString *const JXViewControllerWillAnimateRotation = @"JXViewControllerWillAnimateRotation";

typedef enum {
    JXViewOrientationPortraitStraight = UIInterfaceOrientationPortrait,
    JXViewOrientationPortraitUpsideDown = UIInterfaceOrientationPortraitUpsideDown,
    JXViewOrientationLandscapeLeft = UIInterfaceOrientationLandscapeLeft,
    JXViewOrientationLandscapeRight = UIInterfaceOrientationLandscapeRight,
    JXViewOrientationPortrait = 10, 
    JXViewOrientationLandscape = 11 
} JXViewOrientation;


void JX_SwizzleInstanceMethods(Class c, SEL origSEL, SEL overrideSEL)
{    
    Method origMethod = class_getInstanceMethod(c, origSEL);
    Method overrideMethod = class_getInstanceMethod(c, overrideSEL);
    
    if(class_addMethod(c, origSEL, method_getImplementation(overrideMethod), method_getTypeEncoding(overrideMethod)))
    {
        class_replaceMethod(c, overrideSEL, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    } else
    {
        method_exchangeImplementations(origMethod, overrideMethod);
    }
}

static UIInterfaceOrientation currentInterfaceOrientation = UIInterfaceOrientationPortrait;

#pragma mark -
#pragma mark -

@interface JXOrientation ()

@property (nonatomic, assign) UIView *target;
@property (nonatomic, assign) JXViewOrientation orientation;
@property (nonatomic, retain) NSMutableDictionary *invocations;
@property (nonatomic, retain) NSMutableArray *selectors;

@end

@implementation JXOrientation

@synthesize target = _target;
@synthesize orientation = _orientation;
@synthesize invocations = _invocations;
@synthesize selectors = _selectors;

#pragma mark -

+ (JXOrientation *) orientationWithTarget:(UIView *)target orientation:(JXViewOrientation)orientation
{
    return [[[JXOrientation alloc] initWithTarget:target orientation:orientation] autorelease];
}

- (id)initWithTarget:(UIView *)target orientation:(JXViewOrientation) orientation
{
    self.target = target;
    self.orientation = orientation;
    self.invocations = [NSMutableDictionary dictionary];
    self.selectors = [NSMutableArray array];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(willAnimateRotationNotification:) 
                                                 name:JXViewControllerWillAnimateRotation
                                               object:nil];
    return self;
}

#pragma mark - Proxy Implementation

- (BOOL)isKindOfClass:(Class)aClass;
{
    return [self.target isKindOfClass:aClass];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol;
{
    return [self.target conformsToProtocol:aProtocol];
}

- (BOOL)respondsToSelector:(SEL)aSelector;
{
    return [self.target respondsToSelector:aSelector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    return [self.target methodSignatureForSelector:aSelector];
}

- (void) forwardInvocation:(NSInvocation *)anInvocation
{
    if (self.orientation == JXViewOrientationPortrait) {
        [anInvocation invokeWithTarget:[self.target portraitStraight]];
        [anInvocation invokeWithTarget:[self.target portraitUpsideDown]];        
    }
    else if (self.orientation == JXViewOrientationLandscape) {
        [anInvocation invokeWithTarget:[self.target landscapeLeft]];
        [anInvocation invokeWithTarget:[self.target landscapeRight]];        
    }
    else if ([self.target respondsToSelector:[anInvocation selector]]) {
        [anInvocation setTarget:self.target];
        [self addInvocation:anInvocation];
        [anInvocation invokeWithTarget:nil];
    }
    else
        [super forwardInvocation:anInvocation];
}

- (NSString *) description
{
    NSString *orientationString;
    switch (self.orientation) {
        case JXViewOrientationPortrait:
            orientationString = @"Portrait";
            break;
        case JXViewOrientationPortraitStraight:
            orientationString = @"PortraitStraight";
            break;
        case JXViewOrientationPortraitUpsideDown:
            orientationString = @"PortraitUpsideDown";
            break;
        case JXViewOrientationLandscape:
            orientationString = @"Landscape";
            break;
        case JXViewOrientationLandscapeLeft:
            orientationString = @"LandscapeLeft";
            break;
        case JXViewOrientationLandscapeRight:
            orientationString = @"LandscapeRight";
            break;
        default:
            orientationString = @"Unknown";
            break;
    }
    
    return [NSString stringWithFormat:@"<%@[%@]:%x> : %@",
            NSStringFromClass([self.target class]),
            orientationString, 
            self.target,
            self.selectors];
}

#pragma mark - Rotation Behavior

- (void) willAnimateRotationNotification:(NSNotification *)notification
{    
    NSDictionary *userInfo = [notification userInfo];
    
    UIInterfaceOrientation toInterfaceOrientation;
    [[userInfo objectForKey:@"toInterfaceOrientation"] getValue:&toInterfaceOrientation];
    
    NSTimeInterval duration;
    [[userInfo objectForKey:@"duration"] getValue:&duration];
    
    if (toInterfaceOrientation == self.orientation) 
    {
        for (NSString *selectorString in self.selectors) {
            [[self.invocations objectForKey:selectorString] invokeWithTarget:self.target];
        }
    }
}

#pragma mark - Manage Invocations

- (void) addInvocation:(NSInvocation *)invocation
{
    NSString *selectorString = NSStringFromSelector([invocation selector]);
    
    [_selectors removeObject:selectorString];
    [_selectors addObject:selectorString];
    
    [self.invocations setObject:invocation forKey:selectorString];
    
    if (currentInterfaceOrientation == self.orientation)
        [invocation invokeWithTarget:self.target];
}

- (void) removeActionForSelector:(SEL)aSelector
{
    [self.invocations removeObjectForKey:NSStringFromSelector(aSelector)];
}

#pragma mark - Dealloc

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_invocations release];
    [_selectors release];
    [super dealloc];
}

@end

#pragma mark -
#pragma mark -

static char portraitKey;
static char portraitStraightKey;
static char portraitUpsideDownKey;
static char landscapeKey;
static char landscapeLeftKey;
static char landscapeRightKey;

@implementation UIView (JXOrientation)

- (id) portrait
{
    JXOrientation *portrait = objc_getAssociatedObject(self, &portraitKey);
    
    if (!portrait) {
        portrait = [JXOrientation orientationWithTarget:self orientation:JXViewOrientationPortrait];
        objc_setAssociatedObject (self, &portraitKey, portrait, OBJC_ASSOCIATION_RETAIN);
    }
    
    return [[portrait retain] autorelease];
}
- (id) portraitStraight
{
    JXOrientation *portraitStraight = objc_getAssociatedObject(self, &portraitStraightKey);
    
    if (!portraitStraight) {
        portraitStraight = [JXOrientation orientationWithTarget:self orientation:JXViewOrientationPortraitStraight];
        objc_setAssociatedObject (self, &portraitStraightKey, portraitStraight, OBJC_ASSOCIATION_RETAIN);
    }
    
    return [[portraitStraight retain] autorelease];
}

- (id) portraitUpsideDown
{
    JXOrientation *portraitUpsideDown = objc_getAssociatedObject(self, &portraitUpsideDownKey);
    
    if (!portraitUpsideDown) {
        portraitUpsideDown = [JXOrientation orientationWithTarget:self orientation:JXViewOrientationPortraitUpsideDown];
        objc_setAssociatedObject (self, &portraitUpsideDownKey, portraitUpsideDown, OBJC_ASSOCIATION_RETAIN);
    }
    
    return [[portraitUpsideDown retain] autorelease];
}

- (id) landscape
{
    JXOrientation *landscape = objc_getAssociatedObject(self, &landscapeKey);
    
    if (!landscape) {
        landscape = [JXOrientation orientationWithTarget:self orientation:JXViewOrientationLandscape];
        objc_setAssociatedObject (self, &landscapeKey, landscape, OBJC_ASSOCIATION_RETAIN);
    }
    
    return [[landscape retain] autorelease];
}

- (id) landscapeLeft
{
    JXOrientation *landscapeLeft = objc_getAssociatedObject(self, &landscapeLeftKey);
    
    if (!landscapeLeft) {
        landscapeLeft = [JXOrientation orientationWithTarget:self orientation:JXViewOrientationLandscapeLeft];
        objc_setAssociatedObject (self, &landscapeLeftKey, landscapeLeft, OBJC_ASSOCIATION_RETAIN);
    }
    
    return [[landscapeLeft retain] autorelease];
}

- (id) landscapeRight
{
    JXOrientation *landscapeRight = objc_getAssociatedObject(self, &landscapeRightKey);
    
    if (!landscapeRight) {
        landscapeRight = [JXOrientation orientationWithTarget:self orientation:JXViewOrientationLandscapeRight];
        objc_setAssociatedObject (self, &landscapeRightKey, landscapeRight, OBJC_ASSOCIATION_RETAIN);
    }
    
    return [[landscapeRight retain] autorelease];
}

@end

#pragma mark -
#pragma mark -

static NSInteger JX_rotatingControllers = 0;

@implementation UIViewController (JXOrientation)

+ (void)load
{
    JX_SwizzleInstanceMethods([UIViewController class], @selector(willRotateToInterfaceOrientation:duration:), @selector(JX_willRotateToInterfaceOrientation:duration:));
    JX_SwizzleInstanceMethods([UIViewController class], @selector(willAnimateRotationToInterfaceOrientation:duration:), @selector(JX_willAnimateRotationToInterfaceOrientation:duration:));
    JX_SwizzleInstanceMethods([UIViewController class], @selector(didRotateFromInterfaceOrientation:), @selector(JX_didRotateFromInterfaceOrientation:));
}

- (void) JX_willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    JX_rotatingControllers += 1;
    
    [self JX_willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)JX_willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (JX_rotatingControllers == 1) { // Send notification only once.
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue value:&toInterfaceOrientation withObjCType:@encode(UIInterfaceOrientation)], @"toInterfaceOrientation",
                                  [NSValue value:&duration withObjCType:@encode(NSTimeInterval)], @"duration", nil];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:JXViewControllerWillAnimateRotation 
                                                            object:nil
                                                          userInfo:userInfo];
    }
    
    [self JX_willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void) JX_didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    JX_rotatingControllers -= 1;
    
    if (JX_rotatingControllers == 0)
        currentInterfaceOrientation = self.interfaceOrientation;
    
    [self JX_didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

@end
