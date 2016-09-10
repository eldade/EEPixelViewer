//    Copyright (c) 2016, Eldad Eilam
//    All rights reserved.
//
//    Redistribution and use in source and binary forms, with or without modification, are
//    permitted provided that the following conditions are met:
//
//    1. Redistributions of source code must retain the above copyright notice, this list of
//       conditions and the following disclaimer.
//
//    2. Redistributions in binary form must reproduce the above copyright notice, this list
//       of conditions and the following disclaimer in the documentation and/or other materials
//       provided with the distribution.
//
//    3. Neither the name of the copyright holder nor the names of its contributors may be used
//       to endorse or promote products derived from this software without specific prior written
//       permission.
//
//    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS
//    OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
//    AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
//    CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//    DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
//    WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
//    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "ViewController.h"
#import <Accelerate/Accelerate.h>

@interface ViewController ()

@end

@implementation ViewController

- (void *) imageDataFromUIImage: (UIImage *) image
{
    // First get the image into your data buffer
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);

    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    return rawData;
}

- (nullable NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSArray *keys;
    
    if (component == 0)
        keys = [pixelFormats allKeys];
    else if (component == 1)
        keys = [contentModes allKeys];

    return keys[row];
}

// implement UIPickerViewDelegate's method
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    return pickerView.frame.size.width / 3;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(nullable UIView *)view
{
    
    NSArray *keys;
    
    switch (component)
    {
        case 0:
            keys = sampleImages;
            break;
        case 1:
            keys = pixelFormatSortedList;
            break;
        case 2:
            keys = contentModesSortedList;
            break;
            
        default:
            return 0;
    }
    
    UILabel *label = [[UILabel alloc] initWithFrame: CGRectZero];
    label.text = keys[row];
    label.font = [UIFont systemFontOfSize: 12];
    
    return label;
}


//- (nullable NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component
//{
//    return nil;
//}


// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 3;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    switch (component)
    {
        case 0:
            return sampleImages.count;
        case 1:
            return pixelFormats.count;
        case 2:
            return contentModes.count;
            
        default:
            return 0;
    }
}

//- (void) RGBtoYUVandBack: (void *) rawBuffer
//{
//    vImage_Error err = kvImageNoError;
//    vImage_Flags flags = kvImageNoFlags;//kvImagePrintDiagnosticsToConsole;
//    vImage_YpCbCrPixelRange pixelRange = pixelRangeVideoClamped;
//    vImage_ARGBToYpCbCr outInfo;
//    
//    err = vImageConvert_ARGBToYpCbCr_GenerateConversion(kvImage_ARGBToYpCbCrMatrix_ITU_R_601_4, &pixelRange, &outInfo, kvImageARGB8888, kvImage444CrYpCb8, flags);
//    
//    //    vImageConvert_ARGB8888To422YpCbYpCr8
//    
//    vImage_YpCbCrToARGBMatrix matrix = *kvImage_YpCbCrToARGBMatrix_ITU_R_601_4;
//    
//    
//    char pixels[] = { 0x00, 0x00, 0xff, 0xff, 0xff, 0x00, 0x00, 0xff, 0x00, 0x00, 0xff, 0xff, 0x00, 0x00, 0xff, 0xff };
//    unsigned char yuvPixels[128];
//    vImage_Buffer dest = { yuvPixels, 2, 2, 6};
//    
//    vImage_Buffer srcBuffer = { pixels, 2, 2, 8};
//    
//    uint8_t permuteMap[] = { 3, 2, 1, 0}; // The conversion func expects ARGB so we this tells it to expect RGBA which is our one and only source format:
//    vImageConvert_ARGB8888To444CrYpCb8(&srcBuffer, &dest, &outInfo, permuteMap, flags);
//    
//    // The above produces an image in a format that's completely undefined in the CV pixel format definitions (where the Cr channel precedes Yp),
//    // so we permute to a kCVPixelFormatType_444YpCbCr8 by flipping the first two channels. Note that the vImagePermuteChannels_RGB888 permute function
//    // specifies RGB but it doesn't matter since it's just flipping bytes.
//    
//    uint8_t YpCb_permuteMap[] = {1, 0, 2 };
//    
////    vImagePermuteChannels_RGB888(&dest, &dest, YpCb_permuteMap, flags);
//    
//    // TEST: Let's convert it back:
//    vImage_YpCbCrToARGB conversionInfo;
//    
//    err = vImageConvert_YpCbCrToARGB_GenerateConversion(kvImage_YpCbCrToARGBMatrix_ITU_R_601_4, &pixelRange, &conversionInfo, kvImage444CrYpCb8, kvImageARGB8888, flags);
//    
//    //    vImageConvert_ARGB8888To422YpCbYpCr8
//    
//    //    vImage_YpCbCrToARGBMatrix matrix = *kvImage_YpCbCrToARGBMatrix_ITU_R_601_4;
//    
//    //    uint8_t YpCb_permuteMap[] = {1, 0, 2 };
//    
////    vImagePermuteChannels_RGB888(&dest, &dest, YpCb_permuteMap, flags);
//    char rgbPixels[128];
//    
//    vImage_Buffer destRGB_TEST = { rgbPixels, 2, 2, 8};
//    
//    srcBuffer = dest;
//    
//    uint8_t permuteMap_TEST[] = { 3, 2, 1, 0 }; // The conversion func expects ARGB so we this tells it to expect RGBA which is our one and only source format:
//    vImageConvert_444CrYpCb8ToARGB8888(&srcBuffer, &destRGB_TEST, &conversionInfo, &permuteMap_TEST, 0xfd, kvImagePrintDiagnosticsToConsole );
//    
//    for (int i = 0; i < 12; i += 3)
//    {
//        float Cr = (float) yuvPixels[i] / 255.0;
//        float Yp = (float) yuvPixels[i + 1] / 255.0;
//        float Cb = (float) yuvPixels[i + 2] / 255.0;
//        
//        Yp -= 0.0625;
//        Cr -= 0.5;
//        Cb -= 0.5;
//        
//        Yp *= 1.1643;
//        
//        float r = Yp + Cr * 1.5958;
//        float g = Yp + Cr * -0.81290 + Cb * -0.39173 ;
//        float b = Yp + Cb * 2.017;
////        NSLog(@"R=%f G=%f B=%f\n", r, g, b);
//        NSLog(@"R=%x G=%x B=%x", ((int) r) * 255, ((int) g) * 255, ((int) b) * 255);
//    }
//    
//}

- (void) YpCbCrToRGB: (unsigned char *) yuvPixels
{
    for (int i = 0; i < 12; i += 3)
    {
        float Cb = (float) yuvPixels[i] / 255.0;
        float Yp = (float) yuvPixels[i + 1] / 255.0;
        float Cr = (float) yuvPixels[i + 2] / 255.0;
        
        Yp -= 0.0625;
        Cr -= 0.5;
        Cb -= 0.5;
        
        Yp *= 1.1643;
        
        NSLog(@"Yp=%f Cb=%f Cr=%f\n", Yp, Cb, Cr);
        
        float r = Yp + Cr * 1.5958;
        float g = Yp - Cr * 0.81290 - Cb * 0.39173 ;
        float b = Yp + Cb * 2.017;
        //        NSLog(@"R=%f G=%f B=%f\n", r, g, b);
        
        uint8_t redFinal = (uint8_t) (MAX(MIN(255, r * 255.0), 0));
        uint8_t greenFinal = (uint8_t) (MAX(MIN(255, g * 255.0), 0));
        uint8_t blueFinal = (uint8_t) (MAX(MIN(255, b * 255.0), 0));
        NSLog(@"R=%x G=%x B=%x", redFinal, greenFinal, blueFinal);
    }
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (timer != nil)
    {
        [timer invalidate];
        timer = nil;
    }
    
    [imageConverter reset];
    
    NSString *imageToLoad = sampleImages[[pickerView selectedRowInComponent:0]];
    
    NSString *contentModeName = contentModesSortedList[[pickerView selectedRowInComponent:2]];
    UIViewContentMode contentMode = [contentModes[contentModeName] intValue];
    
    NSString *pixelFormatName = pixelFormatSortedList[[pickerView selectedRowInComponent:1]];
    int pixelFormat = [pixelFormats[pixelFormatName] intValue];
    
    UIImage *sourceImage = [UIImage imageNamed: imageToLoad];
    void *rawBuffer = [self imageDataFromUIImage: sourceImage];
    
    char pixels[] = { 0x00, 0x00, 0xff, 0xff, 0xff, 0x00, 0x00, 0xff, 0x00, 0xff, 0x00, 0xff, 0x00, 0x00, 0xff, 0xff };
    
//    rawBuffer = pixels;
//    sourceImageSize = CGSizeMake(2, 2);
    
    CGSize sourceImageSize = sourceImage.size;
    
    vImage_Buffer sourceBuffer = { rawBuffer, sourceImageSize.height, sourceImageSize.width, sourceImageSize.width * 4 };

    _pixelViewer.pixelFormat = pixelFormat;
    _pixelViewer.contentMode = contentMode;
    _pixelViewer.sourceImageSize = sourceImageSize;
    _pixelViewer.backgroundColor = [UIColor blueColor];
    
    switch (pixelFormat)
    {
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
        case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:
            [imageConverter RGBA32to2PlanarYpCbCr: sourceBuffer pixelFormat: pixelFormat];
            break;
        case kCVPixelFormatType_420YpCbCr8Planar:
            [imageConverter RGBA32to3PlanarYpCbCr: sourceBuffer pixelFormat: pixelFormat];
            break;
        case kCVPixelFormatType_422YpCbCr8:
            [imageConverter RGBA32toInterleaved422YpCbCr: sourceBuffer pixelFormat: pixelFormat];
            break;
        case kCVPixelFormatType_444YpCbCr8:
            [imageConverter RGBA32toInterleaved444YpCbCr: sourceBuffer pixelFormat: pixelFormat];
            break;
        case kCVPixelFormatType_4444AYpCbCr8:
            [imageConverter RGBA32toInterleaved444AYpCbCr8: sourceBuffer pixelFormat: pixelFormat];
            break;
        case kCVPixelFormatType_4444YpCbCrA8:
            [imageConverter RGBA32toInterleaved444YpCbCrA8: sourceBuffer pixelFormat: pixelFormat];
            break;

        case kCVPixelFormatType_16LE565:
        case kCVPixelFormatType_16LE555:
        case kCVPixelFormatType_16LE5551:
            [imageConverter RGBA32to16bpp: sourceBuffer pixelFormat: pixelFormat];
            break;

        case kCVPixelFormatType_24BGR:
        case kCVPixelFormatType_24RGB:
            [imageConverter RGBA32to24bpp: sourceBuffer pixelFormat: pixelFormat];
            break;
        case kCVPixelFormatType_32ARGB:
        case kCVPixelFormatType_32BGRA:
        case kCVPixelFormatType_32ABGR:
        case kCVPixelFormatType_32RGBA:
            [imageConverter RGBA32to32bppRGBA: sourceBuffer pixelFormat: pixelFormat];
            break;
        default:
            break;
    }
    
    free (sourceBuffer.data);
    
    timer = [NSTimer scheduledTimerWithTimeInterval: 1.0 / 60.0 target: self selector:@selector(timerFired:) userInfo: nil repeats: YES];
}

- (void) timerFired: (NSTimer *) timer
{
    EEPixelViewerPlane planes[3];
    for (int i = 0; i < imageConverter.planeCount; i++)
    {
        planes[i] = [imageConverter getPlane: i];
    }
    
    [_pixelViewer displayPixelBufferPlanes: planes count: imageConverter.planeCount withCompletion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"PixelFormats" ofType:@"plist"];
    pixelFormats = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    pixelFormatSortedList = [[pixelFormats allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

    
    plistPath = [[NSBundle mainBundle] pathForResource:@"ContentModes" ofType:@"plist"];
    contentModes = [NSMutableDictionary dictionaryWithContentsOfFile:plistPath];
    contentModesSortedList = [[contentModes allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    plistPath = [[NSBundle mainBundle] pathForResource:@"SampleImages" ofType:@"plist"];
    sampleImages = [NSMutableArray arrayWithContentsOfFile:plistPath];
    
    _formatPicker.dataSource = self;
    _formatPicker.delegate = self;
    _formatPicker.showsSelectionIndicator=NO;
    
    _pixelViewer.fpsIndicator = YES;
    
    imageConverter = [[EESampleImageConverter alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
