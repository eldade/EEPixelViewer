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

#import "SampleImageConverter.h"

@implementation EESampleImageConverter

uint8_t permuteMap_kCVPixelFormatType_32ARGB[4] = { 3, 0, 1, 2 }; // kCVPixelFormatType_32ARGB
uint8_t permuteMap_kCVPixelFormatType_32BGRA[4] = { 2, 1, 0, 3 }; // kCVPixelFormatType_32BGRA
uint8_t permuteMap_kCVPixelFormatType_32ABGR[4] = { 3, 2, 1, 0 }; // kCVPixelFormatType_32ABGR
uint8_t permuteMap_kCVPixelFormatType_32RGBA[4] = { 0, 1, 2, 3 }; // kCVPixelFormatType_32RGBA

vImage_YpCbCrPixelRange pixelRangeFull = { 0, 128, 255, 255, 255, 1, 255, 0 };       // full range 8-bit, clamped to full range
vImage_YpCbCrPixelRange pixelRangeVideoUnclamped = { 16, 128, 235, 240, 255, 0, 255, 1 };      // video range 8-bit, unclamped
vImage_YpCbCrPixelRange pixelRangeVideoClamped = { 16, 128, 235, 240, 235, 16, 240, 16 };    // video range 8-bit, clamped to video range

- (void) reset
{
    for (int i = 0; i < _planeCount; i++)
        free (planes[i].data);

    memset(planes, 0, sizeof(planes));
}

// Convert to kCVPixelFormatType_32ARGB, kCVPixelFormatType_32BGRA, kCVPixelFormatType_32ABGR, or kCVPixelFormatType_32RGBA:
- (void) RGBA32to32bppRGBA: (vImage_Buffer) sourceBuffer pixelFormat: (int) pixelFormat
{
    uint8_t *permuteMap;
    
    vImage_Buffer dest32bpp =  { malloc(sourceBuffer.width * sourceBuffer.height * 4), sourceBuffer.height, sourceBuffer.width, sourceBuffer.width * 4};
    
    switch (pixelFormat)
    {
        case kCVPixelFormatType_32ARGB:
            permuteMap = permuteMap_kCVPixelFormatType_32ARGB;
            break;
        case kCVPixelFormatType_32BGRA:
            permuteMap = permuteMap_kCVPixelFormatType_32BGRA;
            break;
        case kCVPixelFormatType_32ABGR:
            permuteMap = permuteMap_kCVPixelFormatType_32ABGR;
            break;
        case kCVPixelFormatType_32RGBA:
            permuteMap = permuteMap_kCVPixelFormatType_32RGBA;
            break;
        default:
            break;
    }
    
    vImagePermuteChannels_ARGB8888(&sourceBuffer, &dest32bpp, permuteMap, kvImageNoFlags);
    planes[0] = dest32bpp;
    _planeCount = 1;
}

// Convert to kCVPixelFormatType_16LE555, kCVPixelFormatType_16LE5551 or kCVPixelFormatType_16LE565:
- (void) RGBA32to16bpp: (vImage_Buffer) sourceBuffer pixelFormat: (int) pixelFormat
{
    vImage_Buffer dest16bpp =  { malloc(sourceBuffer.width * sourceBuffer.height * 2), sourceBuffer.height, sourceBuffer.width, sourceBuffer.width * 2};
    
    vImage_Error err = vImageConvert_RGBA8888toRGB565(&sourceBuffer, &dest16bpp, kvImageNoFlags);
    
    if (pixelFormat == kCVPixelFormatType_16LE5551 || pixelFormat == kCVPixelFormatType_16LE555)
        vImageConvert_RGB565toRGBA5551(&dest16bpp, &dest16bpp, kvImageConvert_DitherNone, kvImageNoFlags);
    
    planes[0] = dest16bpp;
    _planeCount = 1;
}

// Convert to kCVPixelFormatType_24RGB or kCVPixelFormatType_24BGR:
- (void) RGBA32to24bpp: (vImage_Buffer) sourceBuffer pixelFormat: (int) pixelFormat
{
    vImage_Buffer dest24bpp =  { malloc(sourceBuffer.width * sourceBuffer.height * 3), sourceBuffer.height, sourceBuffer.width, sourceBuffer.width * 3};
    
    vImageConvert_RGBA8888toRGB888(&sourceBuffer, &dest24bpp, kvImageNoFlags);
    
    if (pixelFormat == kCVPixelFormatType_24BGR)
    {
        uint8_t permuteMap[3] = {2, 1, 0};
        vImagePermuteChannels_RGB888(&dest24bpp, &dest24bpp, permuteMap, kvImageNoFlags);
    }
    
    planes[0] = dest24bpp;
    _planeCount = 1;
}

// Convert to kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange or kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:
- (void) RGBA32to2PlanarYpCbCr: (vImage_Buffer) sourceBuffer pixelFormat: (int) pixelFormat
{
    vImage_Error err = kvImageNoError;
    vImage_Flags flags = kvImageNoFlags;
    vImage_YpCbCrPixelRange pixelRange;
    vImage_ARGBToYpCbCr outInfo;
    
    if (pixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
        pixelRange = pixelRangeVideoClamped;
    else
        pixelRange = pixelRangeFull;
    
    err = vImageConvert_ARGBToYpCbCr_GenerateConversion(kvImage_ARGBToYpCbCrMatrix_ITU_R_601_4, &pixelRange, &outInfo, kvImageARGB8888, kvImage420Yp8_CbCr8, flags);
    
    vImage_Buffer destYp = { malloc(sourceBuffer.width * sourceBuffer.height), sourceBuffer.height, sourceBuffer.width, sourceBuffer.width};
    vImage_Buffer destCbCr =  { malloc(sourceBuffer.width * sourceBuffer.height), sourceBuffer.height/2, sourceBuffer.width/2, sourceBuffer.width};
    
    uint8_t permuteMap[] = { 3, 0, 1, 2}; // The conversion func expects ARGB so we this tells it to expect RGBA which is our one and only source format:
    vImageConvert_ARGB8888To420Yp8_CbCr8(&sourceBuffer,  &destYp, &destCbCr, &outInfo, permuteMap, flags);
    
    planes[0] = destYp;
    planes[1] = destCbCr;
    _planeCount = 2;
}

// Convert to kCVPixelFormatType_420YpCbCr8Planar or kCVPixelFormatType_420YpCbCr8PlanarFullRange
- (void) RGBA32to3PlanarYpCbCr: (vImage_Buffer) sourceBuffer pixelFormat: (int) pixelFormat
{
    vImage_Error err = kvImageNoError;
    vImage_Flags flags = kvImageNoFlags;
    vImage_YpCbCrPixelRange pixelRange;
    vImage_ARGBToYpCbCr outInfo;
    
    if (pixelFormat == kCVPixelFormatType_420YpCbCr8Planar)
        pixelRange = pixelRangeVideoClamped;
    else
        pixelRange = pixelRangeFull;
    
    err = vImageConvert_ARGBToYpCbCr_GenerateConversion(kvImage_ARGBToYpCbCrMatrix_ITU_R_601_4, &pixelRange, &outInfo, kvImageARGB8888, kvImage420Yp8_Cb8_Cr8, flags);
    
    vImage_Buffer destYp = { malloc(sourceBuffer.width * sourceBuffer.height), sourceBuffer.height, sourceBuffer.width, sourceBuffer.width};
    vImage_Buffer destCb =  { malloc(sourceBuffer.width * sourceBuffer.height), sourceBuffer.height / 2, sourceBuffer.width / 2, sourceBuffer.width / 2};
    vImage_Buffer destCr =  { malloc(sourceBuffer.width * sourceBuffer.height), sourceBuffer.height / 2, sourceBuffer.width / 2, sourceBuffer.width / 2};
    
    uint8_t permuteMap[] = { 3, 0, 1, 2}; // The conversion func expects ARGB so we this tells it to expect RGBA which is our one and only source format:
    vImageConvert_ARGB8888To420Yp8_Cb8_Cr8(&sourceBuffer,  &destYp, &destCb, &destCr, &outInfo, permuteMap, flags);
    
    planes[0] = destYp;
    planes[1] = destCb;
    planes[2] = destCr;
    _planeCount = 3;
}

// Convert to kCVPixelFormatType_444YpCbCr8:
- (void) RGBA32toInterleaved444YpCbCr: (vImage_Buffer) sourceBuffer pixelFormat: (int) pixelFormat
{
    vImage_Error err = kvImageNoError;
    vImage_Flags flags = kvImageNoFlags;
    vImage_YpCbCrPixelRange pixelRange = pixelRangeVideoClamped;
    vImage_ARGBToYpCbCr outInfo;
    
    err = vImageConvert_ARGBToYpCbCr_GenerateConversion(kvImage_ARGBToYpCbCrMatrix_ITU_R_601_4, &pixelRange, &outInfo, kvImageARGB8888, kvImage444CrYpCb8, flags);
        
    vImage_Buffer dest = { malloc(sourceBuffer.width * sourceBuffer.height * 3), sourceBuffer.height, sourceBuffer.width, sourceBuffer.width * 3};
    
    uint8_t permuteMap[] = { 3, 0, 1, 2}; // The conversion func expects ARGB so we this tells it to expect RGBA which is our one and only source format:
    vImageConvert_ARGB8888To444CrYpCb8(&sourceBuffer, &dest, &outInfo, permuteMap, flags);
    
    // TO DO: still unclear on the actual byte ordering for kCVPixelFormatType_444YpCbCr8 aka 'v308'. Accelerate framework treats it as CrYpCb, but I haven't
    // found any other evidence that that's the actual ordering for that format. I've configured the pixel viewer to expect this ordering for now. If that's
    // wrong, the following PermuteChannels call correctly reverses the order to match the name of the format (YpCbCr).
    
//    // The above produces an image in a format that's completely undefined in the CV pixel format definitions (where the Cr channel precedes Yp),
//    // so we permute to a kCVPixelFormatType_444YpCbCr8 by flipping the first two channels. Note that the vImagePermuteChannels_RGB888 permute function
//    // specifies RGB but it doesn't matter since it's just flipping bytes.
//    
//    uint8_t YpCb_permuteMap[] = {1, 2, 0 };
//    
//    vImagePermuteChannels_RGB888(&dest, &dest, YpCb_permuteMap, flags);
    
    planes[0] = dest;
    _planeCount = 1;
}

// Convert to kCVPixelFormatType_422YpCbCr8
- (void) RGBA32toInterleaved422YpCbCr: (vImage_Buffer) sourceBuffer pixelFormat: (int) pixelFormat
{
    vImage_Error err = kvImageNoError;
    vImage_Flags flags = kvImageNoFlags;//kvImagePrintDiagnosticsToConsole;
    vImage_YpCbCrPixelRange pixelRange = pixelRangeVideoClamped;
    vImage_ARGBToYpCbCr outInfo;
    
    err = vImageConvert_ARGBToYpCbCr_GenerateConversion(kvImage_ARGBToYpCbCrMatrix_ITU_R_601_4, &pixelRange, &outInfo, kvImageARGB8888, kvImage422CbYpCrYp8, flags);
    
    vImage_Buffer dest = { malloc(sourceBuffer.width * sourceBuffer.height * 2), sourceBuffer.height, sourceBuffer.width, sourceBuffer.width * 2};
    
    uint8_t permuteMap[] = { 3, 0, 1, 2}; // The conversion func expects ARGB so we this tells it to expect RGBA which is our one and only source format:
    vImageConvert_ARGB8888To422CbYpCrYp8(&sourceBuffer, &dest, &outInfo, permuteMap, flags);
    
    planes[0] = dest;
    _planeCount = 1;
}

// Convert to kCVPixelFormatType_4444YpCbCrA8
- (void) RGBA32toInterleaved444YpCbCrA8: (vImage_Buffer) sourceBuffer pixelFormat: (int) pixelFormat
{
    vImage_Error err = kvImageNoError;
    vImage_Flags flags = kvImageNoFlags;//kvImagePrintDiagnosticsToConsole;
    vImage_YpCbCrPixelRange pixelRange = pixelRangeVideoClamped;
    vImage_ARGBToYpCbCr outInfo;
    
    err = vImageConvert_ARGBToYpCbCr_GenerateConversion(kvImage_ARGBToYpCbCrMatrix_ITU_R_601_4, &pixelRange, &outInfo, kvImageARGB8888, kvImage444CbYpCrA8, flags);
    
    vImage_Buffer dest = { malloc(sourceBuffer.width * sourceBuffer.height * 4), sourceBuffer.height, sourceBuffer.width, sourceBuffer.width * 4};
    
    uint8_t permuteMap[] = { 3, 0, 1, 2}; // The conversion func expects ARGB so we this tells it to expect RGBA which is our one and only source format:
    vImageConvert_ARGB8888To444CbYpCrA8(&sourceBuffer, &dest, &outInfo, permuteMap, flags);
    
    planes[0] = dest;
    _planeCount = 1;
}

// Convert to kCVPixelFormatType_4444AYpCbCr8
- (void) RGBA32toInterleaved444AYpCbCr8: (vImage_Buffer) sourceBuffer pixelFormat: (int) pixelFormat
{
    vImage_Error err = kvImageNoError;
    vImage_Flags flags = kvImageNoFlags;//kvImagePrintDiagnosticsToConsole;
    vImage_YpCbCrPixelRange pixelRange = pixelRangeVideoClamped;
    vImage_ARGBToYpCbCr outInfo;
    
    err = vImageConvert_ARGBToYpCbCr_GenerateConversion(kvImage_ARGBToYpCbCrMatrix_ITU_R_601_4, &pixelRange, &outInfo, kvImageARGB8888, kvImage444AYpCbCr8, flags);
    
    vImage_Buffer dest = { malloc(sourceBuffer.width * sourceBuffer.height * 4), sourceBuffer.height, sourceBuffer.width, sourceBuffer.width * 4};
    
    uint8_t permuteMap[] = { 3, 0, 1, 2}; // The conversion func expects ARGB so we this tells it to expect RGBA which is our one and only source format:
    vImageConvert_ARGB8888To444AYpCbCr8(&sourceBuffer, &dest, &outInfo, permuteMap, flags);
    
    _planeCount = 1;
    planes[0] = dest;
}

- (EEPixelViewerPlane) getPlane: (int) planeIndex
{
    vImage_Buffer plane = planes[planeIndex];
    EEPixelViewerPlane outputPlane = {plane.data, plane.height, plane.width, plane.rowBytes};
    return outputPlane;
}

@end
