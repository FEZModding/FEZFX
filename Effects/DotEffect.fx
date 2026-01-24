// DotEffect
// 735B2C5FDECA1A372AABF1690291B8F916EF26D55851D42A998040CF7E98169B

#include "BaseEffect.fxh"

float HueOffset;

struct VS_INPUT
{
    float4 Position : POSITION0;
    float4 Color : COLOR0;          // HSV color
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float4 Color : TEXCOORD0;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float4 worldViewPos = TransformPositionToClip(input.Position);
    output.Position = ApplyTexelOffset(worldViewPos);

    float3 color = HSV_RGB(input.Color[0] + HueOffset, input.Color[1], input.Color[2]) * 0.35;
    output.Color.rgb = color * Material_Diffuse;
    output.Color.a = Material_Opacity;
    
    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    return input.Color;
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}