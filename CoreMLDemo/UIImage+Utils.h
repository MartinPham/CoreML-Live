//
//  UIImage+Utils.h
//  CoreMLDemo
//
//

#import <UIKit/UIKit.h>

@interface UIImage (Utils)

- (UIImage *)scaleToSize:(CGSize)size;
- (CVPixelBufferRef)pixelBufferFromCGImage:(UIImage *)image;

@end
