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

// Three-plane YpCbCr shader: Supports all three-plane YpCbCr pixel formats. YpCbCr to RGB conversion
// is done using a coefficient matrix that's uploaded to the GPU via a uniform matrix.
// texture1 contains Yp values, texture2 contains Cb values, texture3 contains Cr values.


precision highp float;

varying highp vec2 TexCoordOut;
uniform sampler2D texture1;
uniform sampler2D texture2;
uniform sampler2D texture3;

uniform mat4 coefficientMatrix;

uniform vec4 YpCbCrOffsets;

void main()
{
    vec4 YpCbCrToConvert;
    
    YpCbCrToConvert[0] = texture2D(texture1, TexCoordOut).r;
    YpCbCrToConvert[1] = texture2D(texture2, TexCoordOut).x;
    YpCbCrToConvert[2] = texture2D(texture3, TexCoordOut).x;
    
    YpCbCrToConvert -= YpCbCrOffsets;
    
    gl_FragColor = YpCbCrToConvert * coefficientMatrix;
}