// SplitCollectorEffect
// 52B68E022A1F74CD272C86E9C5E13418C9FA76F29BA56F2D0B33A593FFFD1B0C

#include "BaseEffect.fxh"

float VaryingOpacity;
float Offset;

struct VS_INPUT
{
    float4 Position : POSITION0;
    float4 Color : COLOR0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float4 CloneSign : TEXCOORD0;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float3 cloneSign = input.Color.rgb * 2.0 - 1.0;
    float4 worldPos = TransformPositionToWorld(input.Position);
    worldPos.xyz += Offset * cloneSign;

    float4 worldViewPos = TransformWorldToClip(worldPos);
    output.Position = ApplyTexelOffset(worldViewPos);
    output.CloneSign = float4(cloneSign, input.Color.a);

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    float3 color = Material_Diffuse;
    float alpha = Material_Opacity;

    if (input.CloneSign.a < 0.25)
    {
        alpha = saturate(alpha * VaryingOpacity);
    }
    else if (input.CloneSign.a < 0.5)
    {
        alpha = saturate(alpha * 0.125 * VaryingOpacity);
    }
    else if (input.CloneSign.a < 0.75)
    {
        alpha = saturate(alpha * 0.125);
    }

    return float4(color, alpha);
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}