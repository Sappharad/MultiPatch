//
//  MPFileTextField.h
//  MultiPatch Text Field with Drag and Drop support
//

#import <Cocoa/Cocoa.h>

@interface MPFileTextField : NSTextField<NSDraggingDestination>

@property (nonatomic, copy) BOOL (^acceptFileDrop)(NSURL*);

@end
