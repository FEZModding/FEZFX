// VignetteEffect
// 0215FF82383DB0B69F57EDCD929FEDC5EBC1B0182736D4C4F30E9F12C3816F49

#include "BaseEffect.fxh"

float SinceStarted;

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
    float horizontalPower = clamp(pow(abs(SinceStarted * 3.0), 30.0), 4.0, 1000000.0);
    float verticalPower = clamp(pow(abs(SinceStarted * 10.0), 15.0), 4.0, 1000000.0);

    float2 offset = input.TexCoord - 0.5;
    float horizontalFactor = saturate(pow(abs(1.0 - offset.x * offset.x * 0.6), horizontalPower));
	float verticalFactor = saturate(pow(abs(1.0 - offset.y * offset.y * 0.6), verticalPower));
    
    float3 color = lerp(1.0, horizontalFactor * verticalFactor, Material_Opacity);
    return float4(color, 1.0);
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}