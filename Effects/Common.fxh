#ifndef COMMON_FXH
#define COMMON_FXH

#define HEX_RGB(hex) float4( \
    (((hex) >> 16) & 0xFF) / 255.0, \
    (((hex) >> 8) & 0xFF) / 255.0, \
    (hex & 0xFF) / 255.0, \
    1.0)

#define HEX_RGBA(hex) float4( \
    (((hex) >> 24) & 0xFF) / 255.0, \
    (((hex) >> 16) & 0xFF) / 255.0, \
    (((hex) >> 8) & 0xFF) / 255.0, \
    ((hex) & 0xFF) / 255.0)

static const float PI = 3.141593;

static const float TAU = 2.0 * PI;

static const float ALPHA_THRESHOLD = 0.00390625;

#endif