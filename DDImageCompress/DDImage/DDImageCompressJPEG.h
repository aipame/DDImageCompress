//
//  UIImage+Compress.h
//  jpegtran
//
//  Created by belik07 on 2018/12/19.
//  Copyright © 2018 wqd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (compressJPEG)
- (NSData *)compressToJpeg:(NSString *)outputFilePath;
+ (BOOL)compressToJpeg:(NSString *)inputFilePath output:(NSString *)outputFilePath;
@end

NS_ASSUME_NONNULL_END
