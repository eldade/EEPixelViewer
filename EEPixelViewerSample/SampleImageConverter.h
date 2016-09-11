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

#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>
#import "EEPixelViewer.h"

@interface EESampleImageConverter : NSObject
{
    vImage_Buffer planes[3];
}

- (void) RGBA32to32bppRGBA: (vImage_Buffer) sourceBuffer pixelFormat: (int) pixelFormat;
- (void) RGBA32to16bpp: (vImage_Buffer) sourceBuffer pixelFormat: (int) pixelFormat;
- (void) RGBA32to24bpp: (vImage_Buffer) sourceBuffer pixelFormat: (int) pixelFormat;
- (void) RGBA32to2PlanarYpCbCr: (vImage_Buffer) sourceBuffer pixelFormat: (int) pixelFormat;
- (void) RGBA32to3PlanarYpCbCr: (vImage_Buffer) sourceBuffer pixelFormat: (int) pixelFormat;
- (void) RGBA32toInterleaved422YpCbCr: (vImage_Buffer) sourceBuffer pixelFormat: (int) pixelFormat;
- (void) RGBA32toInterleaved444YpCbCr: (vImage_Buffer) sourceBuffer pixelFormat: (int) pixelFormat;
- (void) RGBA32toInterleaved444YpCbCrA8: (vImage_Buffer) sourceBuffer pixelFormat: (int) pixelFormat;
- (void) RGBA32toInterleaved444AYpCbCr8: (vImage_Buffer) sourceBuffer pixelFormat: (int) pixelFormat;

- (void) reset;

@property int planeCount;

- (EEPixelViewerPlane) getPlane: (int) plane;

@end
