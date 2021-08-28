//
//  MPFileTextField.m
//  MultiPatch
//

#import "MPFileTextField.h"

@implementation MPFileTextField

-(id)init{
    if(self=[super init]){
        [self registerForDraggedTypes:@[NSURLPboardType]];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)coder{
    if(self=[super initWithCoder:coder]){
        [self registerForDraggedTypes:@[NSURLPboardType]];
    }
    return self;
}

-(void)dealloc{
    if(_acceptFileDrop != nil){
        [_acceptFileDrop release];
        _acceptFileDrop = nil;
    }
    [super dealloc];
}

-(NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender{
    NSArray* fileList = [[sender draggingPasteboard] readObjectsForClasses:@[[NSURL class]] options:nil];
    if(fileList.count == 1){
        NSURL* url = [fileList objectAtIndex:0];
        if(url.isFileURL){
            return NSDragOperationCopy;
        }
    }
    return NSDragOperationNone;
}

-(BOOL)performDragOperation:(id<NSDraggingInfo>)sender{
    if(self.acceptFileDrop){
        NSArray* fileList = [[sender draggingPasteboard] readObjectsForClasses:@[[NSURL class]] options:nil];
        if(fileList.count == 1){
            NSURL* url = [fileList objectAtIndex:0];
            if(url.isFileURL){
                return _acceptFileDrop(url);
            }
        }
    }
    return NO;
}

@end
