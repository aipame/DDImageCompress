//
//  UIImage+Compress.m
//  pngquantLib
//
//  Created by belik07 on 2018/12/14.
//  Copyright © 2018 wqd. All rights reserved.
//

#import "DDImageCompressPNG.h"
#include "lodepng.h"
#include <stdio.h>
#include <stdlib.h>
#include "libimagequant.h"
//#import <CoreGraphics/CoreGraphics.h>


@implementation UIImage (compressPNG)

int progress_callback_function(float progress_percent, void* user_info) {
    NSLog(@"%.2f", progress_percent);
    return 1;
}

- (NSData *)compressToPNG:(NSString *)outputFilePath {
    unsigned int width, height;

    CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider(self.CGImage));
    const uint8_t* data = CFDataGetBytePtr(pixelData);

    width = (int)self.size.width;
    height = (int)self.size.height;

    liq_attr *handle = liq_attr_create();
    liq_attr_set_progress_callback(handle, progress_callback_function, NULL);
    liq_set_quality(handle, 75, 90);//图片质量范围 > 0 < 100;
    liq_set_speed(handle, 3);//压缩速度对压缩比有一定影响的
    liq_image *input_image = liq_image_create_rgba(handle, data, width, height, 0);
        // You could set more options here, like liq_set_quality
    liq_result *quantization_result;
    if (liq_image_quantize(input_image, handle, &quantization_result) != LIQ_OK) {
        fprintf(stderr, "Quantization failed\n");
        return nil;
    }

        // Use libimagequant to make new image pixels from the palette

    size_t pixels_size = width * height;
    unsigned char *raw_8bit_pixels = malloc(pixels_size);
    liq_set_dithering_level(quantization_result, 1.0);

    liq_write_remapped_image(quantization_result, input_image, raw_8bit_pixels, pixels_size);
    const liq_palette *palette = liq_get_palette(quantization_result);

        // Save converted pixels as a PNG file
        // This uses lodepng library for PNG writing (not part of libimagequant)

    LodePNGState state;
    lodepng_state_init(&state);
    state.info_raw.colortype = LCT_PALETTE;
    state.info_raw.bitdepth = 8;
    state.info_png.color.colortype = LCT_PALETTE;
    state.info_png.color.bitdepth = 8;

    for(int i=0; i < palette->count; i++) {
        lodepng_palette_add(&state.info_png.color, palette->entries[i].r, palette->entries[i].g, palette->entries[i].b, palette->entries[i].a);
        lodepng_palette_add(&state.info_raw, palette->entries[i].r, palette->entries[i].g, palette->entries[i].b, palette->entries[i].a);
    }

    unsigned char *output_file_data;
    size_t output_file_size;
    unsigned int out_status = lodepng_encode(&output_file_data, &output_file_size, raw_8bit_pixels, width, height, &state);
    if (out_status) {
        fprintf(stderr, "Can't encode image: %s\n", lodepng_error_text(out_status));
        return nil;
    }
    NSData *output_data = [NSData dataWithBytes:output_file_data length:output_file_size];
    if (outputFilePath) {
        [output_data writeToFile:outputFilePath atomically:YES];
    }
    liq_result_destroy(quantization_result); // Must be freed only after you're done using the palette
    liq_image_destroy(input_image);
    liq_attr_destroy(handle);

    free(raw_8bit_pixels);
    lodepng_state_cleanup(&state);
    return output_data;
}

+ (BOOL)compressToPNG:(NSString *)inputFilePath output:(NSString *)outputFilePath {

    const char  *input_png_file_path = [inputFilePath UTF8String];
    unsigned int width, height;
    unsigned char *raw_rgba_pixels;
    unsigned int status = lodepng_decode32_file(&raw_rgba_pixels, &width, &height, input_png_file_path);
    if (status) {
        fprintf(stderr, "Can't load %s: %s\n", input_png_file_path, lodepng_error_text(status));
        return NO;
    }
    
    liq_attr *handle = liq_attr_create();
    liq_attr_set_progress_callback(handle, progress_callback_function, NULL);
    liq_set_quality(handle, 75, 90);//图片质量范围 > 0 < 100;
    liq_set_speed(handle, 3);//压缩速度对压缩比有一定影响的
    liq_image *input_image = liq_image_create_rgba(handle, raw_rgba_pixels, width, height, 0);
        // You could set more options here, like liq_set_quality
    liq_result *quantization_result;
    if (liq_image_quantize(input_image, handle, &quantization_result) != LIQ_OK) {
        fprintf(stderr, "Quantization failed\n");
        return nil;
    }

        // Use libimagequant to make new image pixels from the palette

    size_t pixels_size = width * height;
    unsigned char *raw_8bit_pixels = malloc(pixels_size);
    liq_set_dithering_level(quantization_result, 1.0);

    liq_write_remapped_image(quantization_result, input_image, raw_8bit_pixels, pixels_size);
    const liq_palette *palette = liq_get_palette(quantization_result);

        // Save converted pixels as a PNG file
        // This uses lodepng library for PNG writing (not part of libimagequant)

    LodePNGState state;
    lodepng_state_init(&state);
    state.info_raw.colortype = LCT_PALETTE;
    state.info_raw.bitdepth = 8;
    state.info_png.color.colortype = LCT_PALETTE;
    state.info_png.color.bitdepth = 8;

    for(int i=0; i < palette->count; i++) {
        lodepng_palette_add(&state.info_png.color, palette->entries[i].r, palette->entries[i].g, palette->entries[i].b, palette->entries[i].a);
        lodepng_palette_add(&state.info_raw, palette->entries[i].r, palette->entries[i].g, palette->entries[i].b, palette->entries[i].a);
    }

    
    unsigned char *output_file_data;
    size_t output_file_size;
    unsigned int out_status = lodepng_encode(&output_file_data, &output_file_size, raw_8bit_pixels, width, height, &state);
    if (out_status) {
        fprintf(stderr, "Can't encode image: %s\n", lodepng_error_text(out_status));
        return NO;
    }

    const char *output_png_file_path = [outputFilePath UTF8String];
    FILE *fp = fopen(output_png_file_path, "wb");
    if (!fp) {
        liq_result_destroy(quantization_result); // Must be freed only after you're done using the palette
        liq_image_destroy(input_image);
        liq_attr_destroy(handle);

        free(raw_8bit_pixels);
        lodepng_state_cleanup(&state);
        fprintf(stderr, "Unable to write to %s\n", output_png_file_path);
        return NO;
    }
    fwrite(output_file_data, 1, output_file_size, fp);
    fclose(fp);


    liq_result_destroy(quantization_result); // Must be freed only after you're done using the palette
    liq_image_destroy(input_image);
    liq_attr_destroy(handle);

    free(raw_8bit_pixels);
    lodepng_state_cleanup(&state);
    return YES;
}


@end
