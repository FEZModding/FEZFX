// ShimmeringPointsEffect
// 06A2B4ED26CB6EC662E30F24EBA840994F0CEF1F12B9654867AD06AF3DE4DA4C

#include "BaseEffect.fxh"

float Saturation;
float3 RandomSeed;

struct VS_INPUT
{
    float4 Position : POSITION0;
    float4 Color : COLOR0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float4 Color : TEXCOORD0;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float4 offset = float4(frac(input.Position.xyz * RandomSeed * 142857.0) * 0.0025, 0.0);
    float4 position = input.Position + offset;

    float4 worldPos = TransformPositionToClip(position);
    float2 texelPosition = (TexelOffset * worldPos.w) + worldPos.xy;
    float2 texelOffset = float2(-sign(input.Color.a) * TexelOffset.x * 4.0, 0.0);

    output.Position.xy = texelPosition + texelOffset;
    output.Position.zw = worldPos.zw;
    output.Color = input.Color;

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    float3 inputColor = (input.Color.rgb * Material_Diffuse) - 1.0;
    float3 color = (inputColor * Saturation) + 1.0;
    float alpha = input.Color.a * Material_Opacity;

    return float4(color, alpha);
}

technique TSM2
{
    pass P0
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}