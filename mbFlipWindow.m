//mbFlipWindow from here: http://macbug.org/macosxsample/canimflipwnd
//Modified for modernization. No license specified...

#import "mbFlipWindow.h"
#import <QuartzCore/QuartzCore.h>

@interface mbFlipWindow () //hiden methods
- (NSWindow *) windowForAnimation:(NSRect)aFrame;
- (CALayer *) layerFromView :(NSView*)view;
NSRect RectToScreen(NSRect aRect, NSView *aView);
NSRect RectFromScreen(NSRect aRect, NSView *aView);
NSRect RectFromViewToView(NSRect aRect, NSView *fromView, NSView *toView);
- (CAAnimation *) animationWithDuration:(CGFloat)time flip:(BOOL)bFlip right:(BOOL)rightFlip;
@end

@interface OutsideWindow : NSWindow
@end

@implementation OutsideWindow
-(NSRect)constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen *)screen{
    //Allow the flipping animation window to go wherever it flipping wants to.
    //If the user flips a window close to the side of the screen, we don't want the animation
    //to jump somewhere else because the animation window got pushed back into screen bounds.
    return frameRect;
}
@end

@implementation mbFlipWindow

@synthesize flipRight;
@synthesize duration;

- (id)init
{
    self = [super init];
    if (self) {
        duration = 1.5;
        flipRight = YES;
    }
    return self;
}

// this method create the window for animation with the image the window
- (NSWindow*) windowForAnimation:(NSRect)aFrame {
    
    OutsideWindow* wnd =  [[OutsideWindow alloc] initWithContentRect:aFrame
                                                 styleMask:NSBorderlessWindowMask
                                                   backing:NSBackingStoreBuffered
                                                     defer:NO];
    [wnd setOpaque:NO];
    [wnd setHasShadow:NO];
    [wnd setBackgroundColor:[NSColor clearColor]];
    [wnd.contentView setWantsLayer:YES];
    
    return wnd;
}

// create layer for animation with image of view
- (CALayer *) layerFromView :(NSView*)view {
    
    NSBitmapImageRep *image = [view bitmapImageRepForCachingDisplayInRect:view.bounds];
    [view cacheDisplayInRect:view.bounds toBitmapImageRep:image];
    
    CALayer *layer = [CALayer layer];
    layer.contents = (id)image.CGImage;
    layer.doubleSided = NO;
    
    // shadow window, used in Mac OS X 10.6+
    [layer setShadowOpacity:0.5f];
    [layer setShadowOffset:CGSizeMake(0,-10)];
    [layer setShadowRadius:15.0f];
    
    return layer;
}

// next 3 methods for translate coordinates
NSRect RectToScreen(NSRect aRect, NSView *aView) {
    aRect = [aView convertRect:aRect toView:nil];
    aRect.origin = [aView.window convertRectToScreen:aRect].origin;
    return aRect;
}

NSRect RectFromScreen(NSRect aRect, NSView *aView) {
    aRect.origin = [aView.window convertRectFromScreen:aRect].origin;
    aRect = [aView convertRect:aRect fromView:nil];
    return aRect;
}

NSRect RectFromViewToView(NSRect aRect, NSView *fromView, NSView *toView) {
    aRect = RectToScreen(aRect, fromView);
    aRect = RectFromScreen(aRect, toView);
    
    return aRect;
}

// create Core Animation are receding and to expand the window
- (CAAnimation *) animationWithDuration:(CGFloat)time flip:(BOOL)bFlip right:(BOOL)rightFlip{
    
    CABasicAnimation *flipAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.y"];
    
    CGFloat startValue, endValue;
    
    if ( rightFlip ) {
        startValue = bFlip ? 0.0f : -M_PI;
        endValue = bFlip ? M_PI : 0.0f;
    } else {
        startValue = bFlip ? 0.0f : M_PI;
        endValue = bFlip ? -M_PI : 0.0f;
    }
    
    flipAnimation.fromValue = [NSNumber numberWithDouble:startValue];
    flipAnimation.toValue = [NSNumber numberWithDouble:endValue];
    
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.toValue = [NSNumber numberWithFloat:1.3f];
    scaleAnimation.duration = time * 0.5;
    scaleAnimation.autoreverses = YES;
    
    CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
    animationGroup.animations = [NSArray arrayWithObjects:flipAnimation, scaleAnimation, nil];
    animationGroup.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animationGroup.duration = time;
    animationGroup.fillMode = kCAFillModeForwards;
    animationGroup.removedOnCompletion = NO;
    
    return animationGroup;
}

- (void) animationDidStop:(CAAnimation *)animation finished:(BOOL)flag {
    if (flag) {
        [mTargetWindow makeKeyAndOrderFront:nil];
        [mAnimationWindow orderOut:nil];
        
        mTargetWindow = nil; //cleanup
        mAnimationWindow = nil;
    }
}

//------------------------

// method for flip windows

- (void) flip:(NSWindow *)activeWindow to:(NSWindow *)targetWindow {
    
    CGFloat durat = duration * (activeWindow.currentEvent.modifierFlags & NSShiftKeyMask ? 10.0 : 1.0);
    CGFloat zDistance = 2500.0f;
    
    NSView *activeView = [activeWindow.contentView superview];
    NSView *targetView = [targetWindow.contentView superview];
    
    // create window for animation
    CGFloat maxWidth  = MAX(NSWidth(activeWindow.frame), NSWidth(targetWindow.frame)) + 250;
    CGFloat maxHeight = MAX(NSHeight(activeWindow.frame), NSHeight(targetWindow.frame)) + 250;
    
    CGRect animationFrame = CGRectMake(NSMidX(activeWindow.frame) - (maxWidth / 2),
                                       NSMidY(activeWindow.frame) - (maxHeight / 2),
                                       maxWidth,
                                       maxHeight);
    
    mAnimationWindow = [self windowForAnimation:NSRectFromCGRect(animationFrame)];
    
    // add perspective
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = -1.0 / zDistance;
    [mAnimationWindow.contentView layer].sublayerTransform = transform;
    
    // move target window to active window
    CGRect targetFrame = CGRectMake(NSMidX(activeWindow.frame) - (NSWidth(targetWindow.frame) / 2 ),
                                    NSMaxY(activeWindow.frame) - NSHeight(targetWindow.frame),
                                    NSWidth(targetWindow.frame),
                                    NSHeight(targetWindow.frame));
    
    [targetWindow setFrame:NSRectFromCGRect(targetFrame) display:NO];
    
    mTargetWindow = targetWindow;
    
    // New Active/Target Layers
    [CATransaction begin];
    CALayer *activeWindowLayer = [self layerFromView: activeView];
    CALayer *targetWindowLayer = [self layerFromView:targetView];
    [CATransaction commit];
    
    activeWindowLayer.frame = NSRectToCGRect(RectFromViewToView(activeView.frame, activeView, [mAnimationWindow contentView]));
    targetWindowLayer.frame = NSRectToCGRect(RectFromViewToView(targetView.frame, targetView, [mAnimationWindow contentView]));
    
    [CATransaction begin];
    [[mAnimationWindow.contentView layer] addSublayer:activeWindowLayer];
    [CATransaction commit];
    
    [mAnimationWindow orderFront:nil];
    
    [CATransaction begin];
    [[mAnimationWindow.contentView layer] addSublayer:targetWindowLayer];
    [CATransaction commit];
    
    // Animate our new layers
    [CATransaction begin];
    CAAnimation *activeAnim = [self animationWithDuration:(durat * 0.5) flip:YES right:flipRight];
    CAAnimation *targetAnim = [self animationWithDuration:(durat * 0.5) flip:NO  right:flipRight];
    [CATransaction commit];
    
    targetAnim.delegate = self;
    [activeWindow orderOut:nil];
    
    [CATransaction begin];
    [activeWindowLayer addAnimation:activeAnim forKey:@"flipWnd"];
    [targetWindowLayer addAnimation:targetAnim forKey:@"flipWnd"];
    [CATransaction commit];
}
@end
