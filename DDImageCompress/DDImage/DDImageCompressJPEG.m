    //
    //  UIImage+Compress.m
    //  jpegtran
    //
    //  Created by belik07 on 2018/12/19.
    //  Copyright © 2018 wqd. All rights reserved.
    //

#import "DDImageCompressJPEG.h"

#include "cdjpeg.h"        /* Common decls for cjpeg/djpeg applications */
#include "transupp.h"        /* Support routines for jpegtran */
#include "jversion.h"        /* for version message */

#ifdef USE_CCOMMAND        /* command-line reader for Macintosh */
#ifdef __MWERKS__
#include <SIOUX.h>              /* Metrowerks needs this */
#include <console.h>        /* ... and this */
#endif
#ifdef THINK_C
#include <console.h>        /* Think declares it here */
#endif
#endif


/*
 * Argument-parsing code.
 * The switch parser is designed to be useful with DOS-style command line
 * syntax, ie, intermixed switches and file names, where only the switches
 * to the left of a given file name affect processing of that file.
 * The main program in this file doesn't actually use this capability...
 */


static const char * progname;    /* program name for error messages */
static char * outfilename;    /* for -outfile switch */
static char * scaleoption;    /* -scale switch */
static JCOPY_OPTION copyoption;    /* -copy switch */
static jpeg_transform_info transformoption; /* image transformation options */




@implementation UIImage (compressJPEG)

- (NSData *)compressToJpeg:(NSString *)outputFilePath {

    NSString *tmpDir = NSTemporaryDirectory();

    NSString *tempInputJpgPath = [NSString stringWithFormat:@"%@%p.jpg",tmpDir,self];
    [self saveToFlie:tempInputJpgPath quality:80];
    NSString *tempOuputJpgPath = outputFilePath;
    if (!tempOuputJpgPath) {
        tempOuputJpgPath = [NSString stringWithFormat:@"%@temp_%p.jpg",tmpDir, self];
    }

    if ([[self class] compressToJpeg:tempInputJpgPath output:tempOuputJpgPath]) {
        return [NSData dataWithContentsOfFile:tempOuputJpgPath];
    };

    return nil;
}

- (void)saveToFlie:(NSString *)outputFilePath quality:(int)quality {
    CGImageRef image = [self CGImage];
    CGSize size = self.size;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    int pixelCount = size.width * size.height;
    uint8_t* rgba = malloc(pixelCount * 4);
    CGContextRef context = CGBitmapContextCreate(rgba, size.width, size.height, 8, 4 * size.width, colorSpace, kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), image);
    CGContextRelease(context);

    // 移除 alpha 通道
    char * rgb = malloc(pixelCount * 3);
    int m = 0;
    int n = 0;
    for(int i=0; i<pixelCount; i++){
        rgb[m++] = rgba[n++];
        rgb[m++] = rgba[n++];
        rgb[m++] = rgba[n++];
        n++;
    }
    free(rgba);

    rgb2jpg([outputFilePath UTF8String], rgb, size.width, size.height, quality);
    // 使用完之后释放内存
    free(rgb);
}

int rgb2jpg(char *jpg_file, char *pdata, int width, int height, int quality)
{
    int depth = 3;
    JSAMPROW row_pointer[1];
    struct jpeg_compress_struct cinfo;
    struct jpeg_error_mgr jerr;
    FILE *outfile;

    if ((outfile = fopen(jpg_file, "wb")) == NULL)
    {
        return -1;
    }

    cinfo.err = jpeg_std_error(&jerr);
    jpeg_create_compress(&cinfo);
    jpeg_stdio_dest(&cinfo, outfile);

    cinfo.image_width      = width;
    cinfo.image_height     = height;
    cinfo.input_components = depth;
    cinfo.in_color_space   = JCS_RGB;
    jpeg_set_defaults(&cinfo);

    jpeg_set_quality(&cinfo, quality, TRUE );
    jpeg_start_compress(&cinfo, TRUE);

    int row_stride = width * depth;
    while (cinfo.next_scanline < cinfo.image_height)
    {
        row_pointer[0] = (JSAMPROW)(pdata + cinfo.next_scanline * row_stride);
        jpeg_write_scanlines(&cinfo, row_pointer, 1);
    }

    jpeg_finish_compress(&cinfo);
    jpeg_destroy_compress(&cinfo);
    fclose(outfile);

    return 0;
}


+ (BOOL)compressToJpeg:(NSString *)inputFilePath output:(NSString *)outputFilePath {

    struct jpeg_decompress_struct srcinfo;
    struct jpeg_compress_struct dstinfo;
    struct jpeg_error_mgr jsrcerr, jdsterr;
    jvirt_barray_ptr * src_coef_arrays;
    jvirt_barray_ptr * dst_coef_arrays;
    /* We assume all-in-memory processing and can therefore use only a
     * single file pointer for sequential input and output operation.
     */
    FILE * fp;
    progname = "jpegtran";    /* in case C library doesn't provide it */

    /* Initialize the JPEG decompression object with default error handling. */
    srcinfo.err = jpeg_std_error(&jsrcerr);
    jpeg_create_decompress(&srcinfo);
    /* Initialize the JPEG compression object with default error handling. */
    dstinfo.err = jpeg_std_error(&jdsterr);
    jpeg_create_compress(&dstinfo);


    init_configure(&dstinfo);
    jsrcerr.trace_level = jdsterr.trace_level;
    srcinfo.mem->max_memory_to_use = dstinfo.mem->max_memory_to_use;

    fp = fopen( [inputFilePath UTF8String], READ_BINARY);
    /* Specify data source for decompression */
    jpeg_stdio_src(&srcinfo, fp);

    /* Enable saving of extra markers that we want to copy */
    jcopy_markers_setup(&srcinfo, copyoption);

    /* Read file header */
    (void) jpeg_read_header(&srcinfo, TRUE);


    if (!jtransform_request_workspace(&srcinfo, &transformoption)) {
        fprintf(stderr, "%s: transformation is not perfect\n", progname);
        return NO;
    }


    /* Read source file as DCT coefficients */
    src_coef_arrays = jpeg_read_coefficients(&srcinfo);

    /* Initialize destination compression parameters from source values */
    jpeg_copy_critical_parameters(&srcinfo, &dstinfo);

    dst_coef_arrays = jtransform_adjust_parameters(&srcinfo, &dstinfo,
                                                   src_coef_arrays,
                                                   &transformoption);


    /* Close input file, if we opened it.
     * Note: we assume that jpeg_read_coefficients consumed all input
     * until JPEG_REACHED_EOI, and that jpeg_finish_decompress will
     * only consume more while (! cinfo->inputctl->eoi_reached).
     * We cannot call jpeg_finish_decompress here since we still need the
     * virtual arrays allocated from the source object for processing.
     */
    if (fp != stdin)
        fclose(fp);

    outfilename = [outputFilePath UTF8String];
    /* Open the output file. */
    if (outfilename != NULL) {
        if ((fp = fopen(outfilename, WRITE_BINARY)) == NULL) {
            fprintf(stderr, "%s: can't open %s for writing\n", progname, outfilename);
            return NO;
        }
    } else {
        /* default output file is stdout */
        fp = write_stdout();
    }

    /* Adjust default compression parameters by re-parsing the options */
    init_configure(&dstinfo);

    /* Specify data destination for compression */
    jpeg_stdio_dest(&dstinfo, fp);

    /* Start compressor (note no image data is actually written here) */
    jpeg_write_coefficients(&dstinfo, dst_coef_arrays);

    /* Copy to the output file any extra markers that we want to preserve */
    jcopy_markers_execute(&srcinfo, &dstinfo, copyoption);

    /* Execute image transformation, if any */
    jtransform_execute_transformation(&srcinfo, &dstinfo,
                                      src_coef_arrays,
                                      &transformoption);

    /* Finish compression and release memory */
    jpeg_finish_compress(&dstinfo);
    jpeg_destroy_compress(&dstinfo);
    (void) jpeg_finish_decompress(&srcinfo);
    jpeg_destroy_decompress(&srcinfo);

    /* Close output file, if we opened it */
    if (fp != stdout)
        fclose(fp);
    return YES;

}


void init_configure(j_compress_ptr cinfo)
{
    scaleoption = NULL;
    copyoption = JCOPYOPT_DEFAULT;
    transformoption.transform = JXFORM_NONE;
    transformoption.perfect = FALSE;
    transformoption.trim = FALSE;
    transformoption.force_grayscale = FALSE;
    transformoption.crop = FALSE;
    cinfo->err->trace_level = 0;

    /* 测试 */
    copyoption = JCOPYOPT_ALL;
    cinfo->optimize_coding = TRUE;

}


@end
