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
        case kCVPixelFormatType_420YpCbCr8PlanarFullRange:
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
