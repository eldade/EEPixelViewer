# EEPixelViewer
EEPixelViewer is a high-performance pixel buffer viewer library for iOS. It is a UIView subclass that uses optimized OpenGL code to take an in-memory pixel buffer and efficiently present it on the screen.

EEPixelViewer is ideal for any kind of situation where you have a pixel buffer coming from any source (whether it's video, remote display, live camera feed, etc.) that needs to be drawn to the screen efficiently, at a high framerate with minimal consumption of system resources.

EEPixelViewer was designed for efficiency and flexibility. The code currently supports 15 different pixel formats such as 24-bit RGB, 32-bit RGBA, several YpCbCr (aka YUV) formats, etc.

EEPixelViewer contains optimized OpenGL code in an attempt to incur the absolute minimum 

| Pixel Format                                   | Supported    | BPP | Planes |
| ---------------------------------------------- |:------------:|:---:|:------:|
| kCVPixelFormatType_420YpCbCr8Planar            | ✅           |  16  |  3|
| kCVPixelFormatType_422YpCbCr8            | ✅           |  16  | 1|
| kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange            | ✅           |  16  | 2|
| kCVPixelFormatType_420YpCbCr8BiPlanarFullRange            | ✅           |  16  |   2|
| kCVPixelFormatType_444YpCbCr8            | ✅           |  16  |  1|
| kCVPixelFormatType_4444YpCbCrA8            | ✅           |  16  |  1|
| kCVPixelFormatType_4444AYpCbCr8            | ✅           |  16  |  1|
| kCVPixelFormatType_24RGB            | ✅           |  16  |  1|
| kCVPixelFormatType_24BGR            | ✅           |  16  |  1|
| kCVPixelFormatType_32ARGB            | ✅           |  16  |  1|
| kCVPixelFormatType_32BGRA            | ✅           |  16  |  1|
| kCVPixelFormatType_32ABGR            | ✅           |  16  |  1|
| kCVPixelFormatType_32RGBA            | ✅           |  16  |  1|
| kCVPixelFormatType_16LE555            | ✅           |  16  |  1|
| kCVPixelFormatType_16LE5551            | ✅           |  16  | 1|
| kCVPixelFormatType_16LE565            | ✅           |  16  |  1 |
