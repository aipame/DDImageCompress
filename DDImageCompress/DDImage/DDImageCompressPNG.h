//
//  UIImage+Compress.h
//  pngquantLib
//
//  Created by belik07 on 2018/12/14.
//  Copyright © 2018 wqd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (compressPNG)
- (NSData *)compressToPNG:(NSString *)outputFilePath;
+ (BOOL)compressToPNG:(NSString *)inputFilePath output:(NSString *)outputFilePath;
@end

NS_ASSUME_NONNULL_END
