// ScanlineEffect
// 4C93D5D8870A4D52F2543721E17AD048345A450510250B93276564CAECC992BC

#include "BaseEffect.fxh"

static const float SCANLINE_FREQ = 300.0 * PI;
static const float3 COLOR_OFFSETS = float3(0.0, 1.0, 2.0);

DECLARE_TEXTURE(BaseTexture);

struct VS_INPUT
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    output.Position = ApplyTexelOffset(input.Position);
    output.TexCoord = input.TexCoord;

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    // Barrel distortion
    float2 offset = input.TexCoord - 0.5;
    float2 bulged = offset * 2.0 + 0.5;
    float vignette = pow(abs(dot(offset, offset)), 1.5);

    // Sample texture
    float2 texCoord = TransformTexCoord(lerp(input.TexCoord, bulged, vignette));
    float4 texColor = SAMPLE_TEXTURE(BaseTexture, texCoord);

    // Scanline phase with RGB offset
    float3 scanline = sin(texCoord.y * SCANLINE_FREQ + Time * 2.0 + COLOR_OFFSETS);
    scanline = scanline * 0.5 + 0.8;

    return float4(scanline * texColor.rgb, Material_Opacity);
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}