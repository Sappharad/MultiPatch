//mbFlipWindow from here: http://macbug.org/macosxsample/canimflipwnd
//Modified for modernization. No license specified...

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface mbFlipWindow : NSObject
{
    BOOL flipRight;
    double duration;
    NSWindow *mAnimationWindow;// windows, created for animation
    NSWindow *mTargetWindow;
}
// flip activeWindow to targetWindow
- (void) flip:(NSWindow *)activeWindow to:(NSWindow *)targetWindow;

@property BOOL flipRight; // YES -rotation right
@property double duration; // time for animation, default value 2.0

@end
