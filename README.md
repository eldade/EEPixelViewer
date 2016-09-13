# EEPixelViewer
EEPixelViewer is a high-performance pixel buffer viewer library for iOS. It is a UIView subclass that uses optimized OpenGL code to take an in-memory pixel buffer and efficiently present it on the screen.

EEPixelViewer is ideal for any kind of situation where you have a pixel buffer coming from any source (whether it's video, remote display protocols such as RDP, etc., live camera feed, etc.) that needs to be drawn to the screen efficiently, at a high framerate with minimal consumption of system resources.

EEPixelViewer was designed for efficiency and flexibility. The code currently supports 15 different pixel formats such as 24-bit RGB, 32-bit RGBA, several YpCbCr (aka YUV) formats, etc.

EEPixelViewer contains optimized OpenGL code in an attempt to incur the absolute minimum amount of resources.

##Usage
EEPixelViewer is easy to use. Create the object either programmatically or through interface builder, and set a few basic parameters. In the following example, we're loading a basic 1-plane 32-bit per pixel RGBA image that is 1024 by 768 in resolution:
```
pixelViewer.pixelFormat = kCVPixelFormatType_32RGBA;
pixelViewer.sourceImageSize = CGSizeMake(1024, 768);
EEPixelViewerPlane plane;
plane.width = 1024;
plane.height = 768;
plane.data = pixelBuffer;
plane.rowBytes = plane.width * 4;
[pixelViewer displayPixelBufferPlanes: &plane count: 1 withCompletion:nil];
```
Note that if you're displaying a video or animation, you will need to make the call to displayPixelBufferPlanes for each frame. The address of the memory buffers is not assumed to be constant across frames, and is not retained by the view. For each call to displayPixelsBufferPlanes, the bits are copied to the GPU and presented to the screen.

## Performance

Specific performance figures obviously depend on the image resolution, the pixel format, and the device's hardware, but generally speaking you can expect decent performance from even outdated iOS devices such as the 4th generation iPad (released in 2012). On that device, a video playing in full Retina resolution (2048 by 1536) will achieve 60 fps for nearly all pixel formats, consuming about 50-60% CPU (about half of one of the CPU cores), and about 30 fps for 24bpp pixel formats. 

##Supported Pixel Formats

**NOTE: Excellent performance means 60FPS when testing a video at the device's native resolution. Formats marked excellent mean that the oldest devices tested (iPhone 5 and the 4th generation iPad) delivered 60 fps.**

| Pixel Format | Supported    | BPP | Planes |Performance|
| :----------- |:------------:|:---:|:------:|:---------:|
| kCVPixelFormatType_420YpCbCr8Planar|✅|16|3|Excellent|
| kCVPixelFormatType_420YpCbCr8PlanarFullRange|✅|16|3|Excellent|
| kCVPixelFormatType_422YpCbCr8|✅|16|1|Excellent|
| kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange|✅|16|2|Excellent|
| kCVPixelFormatType_420YpCbCr8BiPlanarFullRange|✅|16|2|Excellent|
| kCVPixelFormatType_444YpCbCr8|✅|24|1|Excellent on recent devices, fair on older ones |
| kCVPixelFormatType_4444YpCbCrA8|✅|32|1|Excellent|
| kCVPixelFormatType_4444AYpCbCr8|✅|32|1|Excellent|
| kCVPixelFormatType_24RGB|✅|24|1|Excellent on recent devices, fair on older ones |
| kCVPixelFormatType_24BGR|✅|24|1|Excellent on recent devices, fair on older ones |
| kCVPixelFormatType_32ARGB|✅|32|1|Excellent |
| kCVPixelFormatType_32BGRA|✅|32|1|Excellent |
| kCVPixelFormatType_32ABGR|✅|32|1|Excellent |
| kCVPixelFormatType_32RGBA|✅|32|1|Excellent |
| kCVPixelFormatType_16LE555|✅|16|1|Excellent |
| kCVPixelFormatType_16LE5551|✅|16|1|Excellent |
| kCVPixelFormatType_16LE565|✅|16|1|Excellent |
