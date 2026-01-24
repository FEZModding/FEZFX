// ScreenSpaceFisheye
// AB01A8FB53AE054E345AEEF1E5BAFA5B3699B9E7B787BEA9AD4FDEDB16693A99

#include "BaseEffect.fxh"

float2 Intensity;

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
    output.TexCoord = TransformTexCoord(input.TexCoord);

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    // Fisheye distortion
    float2 centered = (input.TexCoord - 0.5) * 2.0;
    float2 offset;
    offset.x = (1.0 - (centered.y * centered.y)) * Intensity.y * centered.x;
    offset.y = (1.0 - (centered.x * centered.x)) * Intensity.x * centered.y;

    float4 texColor = SAMPLE_TEXTURE(BaseTexture, input.TexCoord - offset);
    return float4(texColor.rgb, 1.0);
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}