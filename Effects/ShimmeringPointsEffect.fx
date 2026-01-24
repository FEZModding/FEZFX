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

    float3 seed = frac(input.Position.xyz * 142857.0 * RandomSeed);

    // Center position is transformed
    float4 offset = float4(seed * 0.0025, 0.0);
    float4 worldViewPos = TransformPositionToClip(input.Position + offset);
    output.Position = ApplyTexelOffset(worldViewPos);

    // Actual plane vertex offset is added in screen-space
    output.Position.xy += sign(input.Color.a) * float2(-TexelOffset.x * 4.0, 0.0);
    output.Color = input.Color;

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    float3 color = lerp(1.0, input.Color.rgb * Material_Diffuse, Saturation);
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