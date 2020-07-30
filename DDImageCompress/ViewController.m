//
//  ViewController.m
//  DDImageCompress
//
//  Created by belik07 on 2018/12/22.
//  Copyright © 2018 wqd. All rights reserved.
//
#import "DDImageCompressPNG.h"
#import "DDImageCompressJPEG.h"
#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    double s = 9.7;
    NSString *num = [NSString stringWithFormat:@"%.2f", s];
    double i = [num floatValue];
    NSLog(@"%.12f",i);
    [super viewDidLoad];

}

- (IBAction)compress:(id)sender {

    NSString *dicPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *outPath = [NSString stringWithFormat:@"%@/1001_c.jpg",dicPath];
    NSString *inPath = [[NSBundle mainBundle] pathForResource:@"1001" ofType:@"jpg"];
    UIImage *jpeg = [UIImage imageNamed:@"1001.jpg"];
    [jpeg saveToFlie:outPath quality:80];
    return;
    [jpeg compressToJpeg:outPath];
    outPath = [NSString stringWithFormat:@"%@/1001_cs.jpg",dicPath];
    [UIImage compressToJpeg:inPath output:outPath];


    //PNG：xcode会先优化成非标准PNG所以暂不处理这种图片 测试请用iTunes的文件共享拖到Document下
    outPath = [NSString stringWithFormat:@"%@/1002_c.png",dicPath];
    inPath =  [NSString stringWithFormat:@"%@/Calendar.png",dicPath];
    UIImage *pngImage = [UIImage imageNamed:@"1002"];
    [pngImage compressToPNG:outPath];
    outPath = [NSString stringWithFormat:@"%@/1002_cs.png",dicPath];
    [UIImage compressToPNG:inPath output:outPath];

    outPath = [NSString stringWithFormat:@"%@/1003_c.png",dicPath];
    inPath = [NSString stringWithFormat:@"%@/1003.png",dicPath];
    pngImage = [UIImage imageNamed:@"1003"];
    [pngImage compressToPNG:outPath];
    outPath = [NSString stringWithFormat:@"%@/1003_cs.png",dicPath];
    [UIImage compressToPNG:inPath output:outPath];

}


@end
