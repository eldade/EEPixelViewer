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

#import "EEPixelViewer.h"
#import <QuartzCore/QuartzCore.h>

#import <OpenGLES/ES3/gl.h>

#import "OGLProgramManager.h"

#pragma mark - Internal Definitions

typedef struct {
    float x;
    float y;
} Vertex;

struct RectVertexes
{
    Vertex	bottomLeft;
    Vertex	topLeft;
    Vertex	topRight;
    Vertex	bottomRight;
};

#define RectBottomLeft { -1, -1 }
#define RectTopLeft { -1, 1 }
#define RectTopRight  { 1, 1 }
#define RectBottomRight { 1, -1 }

static Vertex SquareVertices[] =
{
    RectBottomLeft,
    RectTopLeft,
    RectBottomRight,
    RectBottomRight,
    RectTopLeft,
    RectTopRight,
};

static const GLubyte SquareIndices[] =
{
    0, 1, 2,
    3, 4, 5,
};


@interface EEPixelViewer()
{
    OGLProgramManager *program;
    
    GLuint clippedRectVertexBuffer;
    GLuint clippedRectIndexBuffer;
    
    GLuint rectVertexBuffer;
    GLuint rectIndexBuffer;
    
    GLuint textures[4];
    
    UILabel *fpsLabel;
    
    NSDate *lastTimestamp;
    NSTimeInterval totalTime;
    int totalFrames;
    int maxFrames;
    
    struct pixel_buffer_parameters
    {
        GLenum  pixelDataFormat;
        GLenum  dataType;
        GLint   internalFormat;
        int     bytesPerPixel;
    }  pixelBufferParameters[4];
    
    UIViewContentMode pixelViewerContentMode;
}
@end

@implementation EEPixelViewer

#pragma mark - Initialization Code

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    self.context = [[EAGLContext alloc] initWithAPI: kEAGLRenderingAPIOpenGLES3];
    
    if (self.context == nil)
    {
        self.context = [[EAGLContext alloc] initWithAPI: kEAGLRenderingAPIOpenGLES2];
        NSLog(@"EEPixelViewer: Initialized with OpenGL ES 2.0");
    }
    else
    {
        NSLog(@"EEPixelViewer: Initialized with OpenGL ES 3.0");
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame context:(EAGLContext *)context
{
    [EAGLContext setCurrentContext: context];
    self = [super initWithFrame:frame context:context];
    return self;
}

- (void)setupVBOs
{
	[program use];
    glGenBuffers(1, &rectVertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, rectVertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(SquareVertices), SquareVertices, GL_STATIC_DRAW);
    
    glGenBuffers(1, &rectIndexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, rectIndexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(SquareIndices), SquareIndices, GL_STATIC_DRAW);
	
	// Set our clipping rect vertex array (that gets calculated dynamically during scene rendering):
    glGenBuffers(1, &clippedRectVertexBuffer);
    glGenBuffers(1, &clippedRectIndexBuffer);
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    if (fpsLabel != nil)
        fpsLabel.frame = CGRectMake(0, 0, self.bounds.size.width / 2, 30);
    
    [self deleteDrawable];
    [self bindDrawable];
        
    [program use];
    
    [self setupShadersForCropAndScaling];
    
    [self display];

}

- (void) setContext:(EAGLContext *)newContext
{
    if (newContext == nil)
        return;
    
    [EAGLContext setCurrentContext: newContext];
    [super setContext:newContext];
    
    [super setContentMode: UIViewContentModeRedraw];
    
    self.layer.borderColor = [UIColor greenColor].CGColor;
    self.layer.borderWidth = 2.0;
    
    self.enableSetNeedsDisplay = NO;
        
    self.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    self.drawableMultisample = GLKViewDrawableMultisample4X;
    
    glGenTextures(4, (GLuint *) &textures);
    
    [self setupVBOs];
}

#pragma mark - Internal Implementation

- (void) setPixelFormat:(OSType)pixelFormat
{
    [EAGLContext setCurrentContext: self.context];
    _pixelFormat = pixelFormat;
    
    NSString *shaderName = nil;
    
    int planeCount = 0;
    
    switch(_pixelFormat)
    {
        case kCVPixelFormatType_420YpCbCr8Planar:           /* Planar Component Y'CbCr 8-bit 4:2:0. */
        case kCVPixelFormatType_420YpCbCr8PlanarFullRange:  /* Planar Component Y'CbCr 8-bit 4:2:0, full range.*/
            shaderName = @"PixelViewer_YpCbCr_3P";
            planeCount = 3;
            
            glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
            
            for (int plane = 0; plane < planeCount; plane++)
            {
                pixelBufferParameters[plane].dataType = GL_UNSIGNED_BYTE;
                pixelBufferParameters[plane].pixelDataFormat = GL_LUMINANCE;
                pixelBufferParameters[plane].internalFormat = GL_LUMINANCE;
                pixelBufferParameters[plane].bytesPerPixel = 1;
            }

            break;
        case kCVPixelFormatType_422YpCbCr8:     /* Component Y'CbCr 8-bit 4:2:2, ordered Cb Y'0 Cr Y'1 */
            // We treat the 422YpCbCr interleaved format as a 2-plane format (even though it is not).
            // This format is packed as Cb Y'0 Cr Y'1, and so each luma pixel is packed with either
            // a Cb or a Cr value. We first load the luma pixels as a RG 16-bit texture, and tell the shader
            // to only extract the G value (the 2nd byte) as the luma. Then we load another copy of the same
            // data as a 2nd plane, as a width/2 32-bpp texture, from which we extract the Cr and Cb values
            // (which are stored as the 1st and 3rd bytes of each fragment).
            shaderName = @"PixelViewer_YpCbCr_2P";
            planeCount = 2;
            
            glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
            
            pixelBufferParameters[0].dataType = GL_UNSIGNED_BYTE;
            pixelBufferParameters[0].pixelDataFormat = GL_RG;
            pixelBufferParameters[0].internalFormat = GL_RG8;
            pixelBufferParameters[0].bytesPerPixel = 2;

            pixelBufferParameters[1].dataType = GL_UNSIGNED_BYTE;
            pixelBufferParameters[1].pixelDataFormat = GL_RGBA;
            pixelBufferParameters[1].internalFormat = GL_RGBA8;
            pixelBufferParameters[1].bytesPerPixel = 4;

            break;
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:   /*  Bi-Planar Component Y'CbCr 8-bit 4:2:0, video-range */
        case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:    /* Bi-Planar Component Y'CbCr 8-bit 4:2:0, full-range */
            shaderName = @"PixelViewer_YpCbCr_2P";
            planeCount = 2;
            
            glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
            
            pixelBufferParameters[0].dataType = GL_UNSIGNED_BYTE;
            pixelBufferParameters[0].pixelDataFormat = GL_LUMINANCE;
            pixelBufferParameters[0].internalFormat = GL_LUMINANCE;
            pixelBufferParameters[0].bytesPerPixel = 1;
            
            pixelBufferParameters[1].dataType = GL_UNSIGNED_BYTE;
            pixelBufferParameters[1].pixelDataFormat = GL_RG;
            pixelBufferParameters[1].internalFormat = GL_RG8;
            pixelBufferParameters[1].bytesPerPixel = 2;
            
            break;
            
        case kCVPixelFormatType_444YpCbCr8:     /* Component Y'CbCr 8-bit 4:4:4 */
            shaderName = @"PixelViewer_YpCbCrA_1P";
            planeCount = 1;
            
            glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
            
            pixelBufferParameters[0].dataType = GL_UNSIGNED_BYTE;
            pixelBufferParameters[0].pixelDataFormat = GL_RGB;
            pixelBufferParameters[0].internalFormat = GL_RGB8;
            pixelBufferParameters[0].bytesPerPixel = 3;
            
            break;
        case kCVPixelFormatType_4444YpCbCrA8:   /* Component Y'CbCrA 8-bit 4:4:4:4, ordered Cb Y' Cr A */
        case kCVPixelFormatType_4444AYpCbCr8:   /* Component Y'CbCrA 8-bit 4:4:4:4, ordered A Y' Cb Cr, full range alpha, video range Y'CbCr. */
            shaderName = @"PixelViewer_YpCbCrA_1P";
            planeCount = 1;
            
            glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
            
            pixelBufferParameters[0].dataType = GL_UNSIGNED_BYTE;
            pixelBufferParameters[0].pixelDataFormat = GL_RGBA;
            pixelBufferParameters[0].internalFormat = GL_RGBA8;
            pixelBufferParameters[0].bytesPerPixel = 4;

            break;
            
        case kCVPixelFormatType_24RGB:      /* 24 bit RGB */
        case kCVPixelFormatType_24BGR:      /* 24 bit BGR */
            shaderName = @"PixelViewer_RGBA";
            pixelBufferParameters[0].dataType = GL_UNSIGNED_BYTE;
            pixelBufferParameters[0].pixelDataFormat = GL_RGB;
            pixelBufferParameters[0].internalFormat = GL_RGB8;
            pixelBufferParameters[0].bytesPerPixel = 3;

            planeCount = 1;
            glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
            break;
            
        case kCVPixelFormatType_32ARGB:     /* 32 bit ARGB */
        case kCVPixelFormatType_32BGRA:     /* 32 bit BGRA */
        case kCVPixelFormatType_32ABGR:     /* 32 bit ABGR */
        case kCVPixelFormatType_32RGBA:     /* 32 bit RGBA */
            shaderName = @"PixelViewer_RGBA";
            pixelBufferParameters[0].dataType = GL_UNSIGNED_BYTE;
            pixelBufferParameters[0].pixelDataFormat = GL_RGBA;
            pixelBufferParameters[0].internalFormat = GL_RGBA8;
            pixelBufferParameters[0].bytesPerPixel = 4;

            planeCount = 1;
            glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
            break;
            
        case kCVPixelFormatType_16LE555:      /* 16 bit BE RGB 555 */
            shaderName = @"PixelViewer_RGB";
            pixelBufferParameters[0].dataType = GL_UNSIGNED_SHORT_5_5_5_1;
            pixelBufferParameters[0].pixelDataFormat = GL_RGBA;
            pixelBufferParameters[0].internalFormat = GL_RGB5_A1;
            pixelBufferParameters[0].bytesPerPixel = 2;
            planeCount = 1;
            glPixelStorei(GL_UNPACK_ALIGNMENT, 2);
            break;
        case kCVPixelFormatType_16LE5551:     /* 16 bit LE RGB 5551 */
            shaderName = @"PixelViewer_RGBA";
            pixelBufferParameters[0].dataType = GL_UNSIGNED_SHORT_5_5_5_1;
            pixelBufferParameters[0].pixelDataFormat = GL_RGBA;
            pixelBufferParameters[0].internalFormat = GL_RGB5_A1;
            pixelBufferParameters[0].bytesPerPixel = 2;
            planeCount = 1;
            glPixelStorei(GL_UNPACK_ALIGNMENT, 2);
            break;
        case kCVPixelFormatType_16LE565:      /* 16 bit BE RGB 565 */
            shaderName = @"PixelViewer_RGBA";
            pixelBufferParameters[0].dataType = GL_UNSIGNED_SHORT_5_6_5;
            pixelBufferParameters[0].pixelDataFormat = GL_RGB;
            pixelBufferParameters[0].internalFormat = GL_RGB565;
            pixelBufferParameters[0].bytesPerPixel = 2;
            
            planeCount = 1;
            glPixelStorei(GL_UNPACK_ALIGNMENT, 2);
            break;
            
    }
    
    program = [OGLProgramManager programWithVertexShader:@"VertexShader" fragmentShader:shaderName];
    
    switch(_pixelFormat)
    {
            // We use the same shader for all 32-bit RGBA type formats, and the shader loads a
            // permute map that can use any color/alpha ordering:
        case kCVPixelFormatType_24BGR:
            glUniform4i([program uniform:@"PermuteMap"], 2, 1, 0, 3);
            break;
        case kCVPixelFormatType_32ARGB:
            glUniform4i([program uniform:@"PermuteMap"], 1, 2, 3, 0);      
            break;
        case kCVPixelFormatType_32BGRA:
            glUniform4i([program uniform:@"PermuteMap"], 2, 1, 0, 3);
            break;
        case kCVPixelFormatType_32ABGR:
            glUniform4i([program uniform:@"PermuteMap"], 3, 2, 1, 0);
            break;
        case kCVPixelFormatType_32RGBA:
            glUniform4i([program uniform:@"PermuteMap"], 0, 1, 2, 3);
            break;
        case kCVPixelFormatType_16LE555:
        case kCVPixelFormatType_16LE5551:
            glUniform4i([program uniform:@"PermuteMap"], 0, 1, 2, 3);
            break;
        case kCVPixelFormatType_422YpCbCr8:
            glUniform4i([program uniform:@"PermuteMap"], 1, 0, 2, 0);
            [self setupYpCbCrCoefficientsWithVideoRange];
            break;
            
        case kCVPixelFormatType_4444AYpCbCr8:
            glUniform4i([program uniform:@"PermuteMap"], 1, 2, 3, 0);
            [self setupYpCbCrCoefficientsWithVideoRange];
            break;

        case kCVPixelFormatType_4444YpCbCrA8:
            // ordered Cb Y' Cr A. Our shader expects Y' Cb Cr A.
            glUniform4i([program uniform:@"PermuteMap"], 1, 0, 2, 3);
            [self setupYpCbCrCoefficientsWithVideoRange];
            break;
            
        case kCVPixelFormatType_444YpCbCr8:
            glUniform4i([program uniform:@"PermuteMap"], 0, 1, 2, 3);
        case kCVPixelFormatType_420YpCbCr8Planar:
            [self setupYpCbCrCoefficientsWithVideoRange];
            break;
        case kCVPixelFormatType_420YpCbCr8PlanarFullRange:
            [self setupYpCbCrCoefficientsWithFullRange];
            break;

        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
            glUniform4i([program uniform:@"PermuteMap"], 0, 0, 1, 0);
            [self setupYpCbCrCoefficientsWithVideoRange];
            break;
        case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:
            glUniform4i([program uniform:@"PermuteMap"], 0, 0, 1, 0);
            [self setupYpCbCrCoefficientsWithFullRange];
            break;

        default:
            glUniform4i([program uniform:@"PermuteMap"], 0, 1, 2, 3);
            break;
    }
    
    glEnableVertexAttribArray([program attribute: @"Position"]);
    
    for (int texture = 0 ; texture < planeCount; texture++)
        glUniform1i([program uniform: [NSString stringWithFormat:@"texture%d", texture + 1]], texture);
    
    if (CGSizeEqualToSize(self.sourceImageSize, CGSizeZero) != false)
        [self setupShadersForCropAndScaling];
}

- (CGRect) calculateAspectFitFillRect
{
	CGFloat scale;
	CGRect scaledRect;
    if (pixelViewerContentMode == UIViewContentModeScaleAspectFit)
    {
        scale = MIN( self.drawableWidth / self.textureCropRect.size.width,
                    self.drawableHeight / self.textureCropRect.size.height);
    }
    else
    {
        scale = MAX( self.drawableWidth / self.textureCropRect.size.width,
                    self.drawableHeight / self.textureCropRect.size.height);
    }
	
	scaledRect.origin.x = (self.drawableWidth - self.textureCropRect.size.width * scale) / 2;
	scaledRect.origin.y = (self.drawableHeight - self.textureCropRect.size.height * scale) / 2;
	
	scaledRect.size.width = self.textureCropRect.size.width * scale;
	scaledRect.size.height = self.textureCropRect.size.height * scale;
	
	return scaledRect;
}

- (void) setSourceImageSize:(CGSize)sourceImageSize
{
    _sourceImageSize = sourceImageSize;
    _textureCropRect = CGRectMake(0, 0, sourceImageSize.width, sourceImageSize.height);
}

- (void) setupShadersForCropAndScaling
{
	CGSize viewSize = CGSizeMake(self.drawableWidth, self.drawableHeight);
	CGPoint scaleFactor = CGPointMake(self.sourceImageSize.width / self.drawableWidth, self.sourceImageSize.height / self.drawableHeight);
	CGPoint textureOffset = CGPointMake(0.0, 0.0);
		
	CGFloat cropCoordinates[4] = { 0, viewSize.height, viewSize.width, 0};
    
	switch (self.contentMode) {
		case UIViewContentModeTopLeft:
			cropCoordinates[0] = self.textureCropRect.origin.x;
			cropCoordinates[1] = viewSize.height - self.textureCropRect.origin.y;
			cropCoordinates[2] = self.textureCropRect.origin.x + self.textureCropRect.size.width;
			cropCoordinates[3] = viewSize.height - (self.textureCropRect.origin.y + self.textureCropRect.size.height);
			break;
        case UIViewContentModeLeft:
            cropCoordinates[0] = self.textureCropRect.origin.x;
            cropCoordinates[1] = (viewSize.height - self.textureCropRect.size.height) / 2;
            cropCoordinates[2] = self.textureCropRect.origin.x + self.textureCropRect.size.width;
            cropCoordinates[3] = cropCoordinates[1] + self.textureCropRect.size.height;
            textureOffset = CGPointMake(0, cropCoordinates[1] / viewSize.height);
            break;
        case UIViewContentModeBottom:
            cropCoordinates[0] = (viewSize.width - self.textureCropRect.size.width) / 2;
            cropCoordinates[1] = self.textureCropRect.size.height;
            cropCoordinates[2] = cropCoordinates[0] + self.textureCropRect.size.width;
            cropCoordinates[3] = 0;
            textureOffset = CGPointMake(cropCoordinates[0] / viewSize.width, 1 - cropCoordinates[1] / viewSize.height);
            break;
        case UIViewContentModeBottomLeft:
            cropCoordinates[0] = self.textureCropRect.origin.x;
            cropCoordinates[1] = self.textureCropRect.size.height;
            cropCoordinates[2] = self.textureCropRect.origin.x + self.textureCropRect.size.width;
            cropCoordinates[3] = 0;
            textureOffset = CGPointMake(0, 1 - cropCoordinates[1] / viewSize.height);
            break;
        case UIViewContentModeRight:
            cropCoordinates[0] = viewSize.width - self.textureCropRect.size.width;
            cropCoordinates[1] = (viewSize.height - self.textureCropRect.size.height) / 2;
            cropCoordinates[2] = viewSize.width;
            cropCoordinates[3] = cropCoordinates[1] + self.textureCropRect.size.height;
            textureOffset = CGPointMake(cropCoordinates[0] / viewSize.width, cropCoordinates[1] / viewSize.height);
            break;
    
        case UIViewContentModeBottomRight:
            cropCoordinates[0] = viewSize.width - self.textureCropRect.size.width;
            cropCoordinates[1] = self.textureCropRect.size.height;
            cropCoordinates[2] = viewSize.width;
            cropCoordinates[3] = 0;
            textureOffset = CGPointMake(cropCoordinates[0] / viewSize.width, 1 - cropCoordinates[1] / viewSize.height);
            break;

        case UIViewContentModeTopRight:
            cropCoordinates[0] = viewSize.width - self.textureCropRect.size.width;
            cropCoordinates[1] = viewSize.height - self.textureCropRect.origin.y;
            cropCoordinates[2] = viewSize.width;
            cropCoordinates[3] = viewSize.height - (self.textureCropRect.origin.y + self.textureCropRect.size.height);
            textureOffset = CGPointMake(cropCoordinates[0] / viewSize.width, 0);
            break;
        case UIViewContentModeTop:
            cropCoordinates[0] = (viewSize.width - self.textureCropRect.size.width) / 2;
            cropCoordinates[1] = viewSize.height - self.textureCropRect.origin.y;
            cropCoordinates[2] = cropCoordinates[0] + self.textureCropRect.size.width;
            cropCoordinates[3] = viewSize.height - (self.textureCropRect.origin.y + self.textureCropRect.size.height);
            textureOffset = CGPointMake(cropCoordinates[0] / viewSize.width, 0);
            break;
        case UIViewContentModeCenter:
            cropCoordinates[0] = (viewSize.width - self.textureCropRect.size.width) / 2;
            cropCoordinates[1] = (viewSize.height - self.textureCropRect.size.height) / 2;
            cropCoordinates[2] = cropCoordinates[0] + self.textureCropRect.size.width;
            cropCoordinates[3] = cropCoordinates[1] + self.textureCropRect.size.height;
            textureOffset = CGPointMake(cropCoordinates[0] / viewSize.width, cropCoordinates[1] / viewSize.height);
            break;
		case UIViewContentModeScaleToFill:
            scaleFactor.x = 1.0;
            scaleFactor.y = 1.0;
			break;
		case UIViewContentModeScaleAspectFill:
		case UIViewContentModeScaleAspectFit:
		{
            CGRect fittedRect;

            scaleFactor = CGPointMake(self.sourceImageSize.width / self.textureCropRect.size.width,
                                      self.sourceImageSize.height / self.textureCropRect.size.height);
            
            fittedRect = [self calculateAspectFitFillRect];

            textureOffset = CGPointMake(fittedRect.origin.x / self.drawableWidth, fittedRect.origin.y / self.drawableHeight);
            scaleFactor = CGPointMake(scaleFactor.x * (fittedRect.size.width / self.drawableWidth), scaleFactor.y * (fittedRect.size.height / self.drawableHeight));
			
			cropCoordinates[0] = fittedRect.origin.x;
			cropCoordinates[1] = self.drawableHeight - fittedRect.origin.y;
			cropCoordinates[2] = fittedRect.origin.x + fittedRect.size.width;
			cropCoordinates[3] = self.drawableHeight - (fittedRect.origin.y + fittedRect.size.height);
			
			break;
		}
		default:
			break;
	}
    
	// Convert cropCoordinates to vertex coordinates (-1.0 -> 1.0). We do (x * 2 - 1) in order to normalize the values into a -1 -> 1.0 coordinate system. We essentially use the vertex array in order to clip the texture as specified.
	struct RectVertexes rectVertexes;
	rectVertexes.topLeft.x = cropCoordinates[0] / self.drawableWidth * 2 - 1;
	rectVertexes.topLeft.y = cropCoordinates[1] / self.drawableHeight * 2 - 1;

	rectVertexes.bottomLeft.x = cropCoordinates[0] / self.drawableWidth * 2 - 1;
	rectVertexes.bottomLeft.y = cropCoordinates[3] / self.drawableHeight * 2 - 1;

	rectVertexes.topRight.x = cropCoordinates[2] / self.drawableWidth * 2 - 1;
	rectVertexes.topRight.y = cropCoordinates[1] / self.drawableHeight * 2 - 1;

	rectVertexes.bottomRight.x = cropCoordinates[2] / self.drawableWidth * 2 - 1;
	rectVertexes.bottomRight.y = cropCoordinates[3] / self.drawableHeight * 2 - 1;
	
	Vertex finalVertexes[] = { rectVertexes.bottomLeft, rectVertexes.topLeft, rectVertexes.bottomRight, rectVertexes.bottomRight, rectVertexes.topLeft, rectVertexes.topRight };
	
    glBindBuffer(GL_ARRAY_BUFFER, clippedRectVertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(finalVertexes), finalVertexes, GL_STATIC_DRAW);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, clippedRectIndexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(SquareIndices), SquareIndices, GL_STATIC_DRAW);
	
	glVertexAttribPointer([program attribute:@"Position"], 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 2, 0);
	
	glUniform2f([program uniform: @"scaleFactor"], scaleFactor.x, scaleFactor.y);
	glUniform2f([program uniform:@"textureOffset"], textureOffset.x, textureOffset.y);
}

- (void) setupYpCbCrCoefficientsWithFullRange
{
    // BT.601 colorspace, full range:
    float coefficientMatrix[] = {   1.0,  0.000,  1.402, 0.0,
                                    1.0,  -0.34414, -0.71414, 0.0,
                                    1.0,  1.772,  0.000, 0.0,
                                    0.0, 0.0, 0.0, 1.0 };
    
    glUniformMatrix4fv([program uniform: @"coefficientMatrix"], 1, GL_FALSE, coefficientMatrix);
    
    glUniform4f([program uniform: @"YpCbCrOffsets"], 0.0, 0.5, 0.5, 0.0);
}

- (void) setupYpCbCrCoefficientsWithVideoRange
{
    // BT.601 colorspace, video range:
    float coefficientMatrix[] = {   1.1643,  0.000,  1.5958, 0.0,
                                    1.1643,  -0.39173, -0.81290, 0.0,
                                    1.1643,  2.017,  0.000, 0.0,
                                    0.0, 0.0, 0.0, 1.0 };
    
    glUniformMatrix4fv([program uniform: @"coefficientMatrix"], 1, GL_FALSE, coefficientMatrix);
    
    
    glUniform4f([program uniform: @"YpCbCrOffsets"], 0.0625, 0.5, 0.5, 0.0);
}

- (void) loadTextureForPlane: (EEPixelViewerPlane *) plane forTextureIndex: (int) textureIndex
{
    glActiveTexture(GL_TEXTURE0 + textureIndex);
    
    glBindTexture(GL_TEXTURE_2D, textures[textureIndex]);
    
    if (self.context.API == kEAGLRenderingAPIOpenGLES3)
    {
        glPixelStorei(GL_UNPACK_ROW_LENGTH, (GLint) plane->rowBytes / pixelBufferParameters[textureIndex].bytesPerPixel);
    }
    else
    {
        // For OpenGL ES 2.0 we set internal format to the same as the incoming buffer format:
        pixelBufferParameters[textureIndex].internalFormat = pixelBufferParameters[textureIndex].pixelDataFormat;
    }
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glTexImage2D(GL_TEXTURE_2D,                                         // target
                 0,                                                     // level
                 pixelBufferParameters[textureIndex].internalFormat,    // internalFormat
                 (GLsizei) plane->width,                                // width
                 (GLsizei) plane->height,                               // height
                 0,                                                     // border
                 pixelBufferParameters[textureIndex].pixelDataFormat,   // format
                 pixelBufferParameters[textureIndex].dataType,          // type
                 plane->data);                                          // pixels
    
    GLenum errorCode = glGetError();
    
    if (errorCode != GL_NO_ERROR)
        NSLog(@"glTexImage2D failed with error %d", errorCode);
}

- (void) drawRect:(CGRect)rect
{
    // First make sure we don't try to run OGL code in the background -- it crashes the app:
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive)
        return;

    [EAGLContext setCurrentContext:self.context];
	
	[program use];
    
    CGFloat red, green, blue, alpha;
    [self.backgroundColor getRed: &red green: &green blue: &blue alpha: &alpha];
    glClearColor(red, green, blue, alpha);
    glClear(GL_COLOR_BUFFER_BIT);
	
	glUniform4f([program uniform:@"VertexPositionScale"], 1.0, 1.0, 1.0, 1.0);
		
	glUniform4f([program uniform:@"VertexPositionShift"], 0.0, 0.0, 0.0, 0.0);
	
	glViewport(0, 0, (GLsizei) self.drawableWidth, (GLsizei) self.drawableHeight);
	
	glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, 0);
    
    if (_fpsIndicator == YES)
        [self updateFPSIndicator];
}

- (void) setFpsIndicator:(BOOL)fpsIndicator
{
    if (fpsIndicator == YES)
    {
        fpsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        fpsLabel.textColor = [UIColor whiteColor];
        fpsLabel.backgroundColor = [UIColor blackColor];
        [self addSubview: fpsLabel];
        
        fpsLabel.text = @"";
        maxFrames = 30;
    }
    _fpsIndicator = fpsIndicator;
}

- (void) updateFPSIndicator
{
    NSTimeInterval latestInterval = 0;
    
    if (lastTimestamp != nil)
        latestInterval = -[lastTimestamp timeIntervalSinceNow];
    
    if (totalFrames >= maxFrames)
    {
        totalTime -= (totalTime / totalFrames);
        totalFrames --;
    }
    
    totalFrames++;
    totalTime += latestInterval;
    
    [fpsLabel performSelectorOnMainThread: @selector(setText:) withObject:[NSString stringWithFormat: @"Average FPS:%.0f", (float) totalFrames / (float) totalTime] waitUntilDone:NO];
    lastTimestamp = [NSDate date];
}

- (void) display
{
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive)
        return;
    
    [program use];
    
    [self setupShadersForCropAndScaling];
    
    [super display];
}

- (void) setContentMode:(UIViewContentMode)contentMode
{
    pixelViewerContentMode = contentMode;
}

- (UIViewContentMode) contentMode
{
    return pixelViewerContentMode;
}

- (void) dealloc
{

    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[EAGLContext setCurrentContext: self.context];
	
	glDeleteBuffers(1, &rectVertexBuffer);
	glDeleteBuffers(1, &rectIndexBuffer);
}

#pragma mark - Public API
- (void) displayPixelBufferPlanes:(EEPixelViewerPlane *)planes count:(int)planeCount withCompletion: (void (^)())completionBlock
{
    [self displayPixelBufferPlanes: planes count:planeCount];
    
    if (completionBlock != nil)
        completionBlock();
}

- (void) displayPixelBufferPlanes: (EEPixelViewerPlane *) planes count: (int) planeCount
{
    [EAGLContext setCurrentContext: self.context];
    [program use];
    
    if (_pixelFormat == kCVPixelFormatType_422YpCbCr8)
    {
        // Special case for an interleaved 4:2:2 YpCbCr case because we need to load the same texture twice in
        // order to correctly parse this one:
        [self loadTextureForPlane: &planes[0] forTextureIndex: 0];
        planes[0].width = planes[0].width / 2;
        [self loadTextureForPlane: &planes[0] forTextureIndex: 1];
    }
    else
    {
        for (int i = 0; i < planeCount; i++)
        {
            [self loadTextureForPlane: &planes[i] forTextureIndex: i];
        }
    }
    
    [self display];
}

@end
