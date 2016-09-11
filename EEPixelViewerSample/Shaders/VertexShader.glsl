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

attribute vec2 Position;
varying vec2 TexCoordOut;
uniform vec4 VertexPositionShift;
uniform vec4 VertexPositionScale;

uniform highp vec2 textureOffset;
uniform highp vec2 scaleFactor;

// textureOffset is the texture's origin on the view, relative to top left. Zero means the texture aligns with the top-left of the view.
// Positive values shift the texture lower and to the right (creating a gap in the top-right corner of the view), and negative values push 
// the texture to the top left and therefore crop the top left. The range is -1 to 1.

// scaleFactor is the size of the texture. 1.0 is original size, 2.0 is double size, and 0.5 is half size, etc.

void main(void) {
    TexCoordOut = (Position * vec2(0.5, -0.5) + vec2(0.5, 0.5)) + -textureOffset;
	
	TexCoordOut *= vec2(1.0, 1.0) / scaleFactor;

    gl_Position = vec4(Position.x, Position.y, 0, 1.0) * VertexPositionScale + VertexPositionShift;
}