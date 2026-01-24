// MapEffect
// 4FE19FCEEC9263809FBE71E54A752676CE32719076062E7B3F7605BA4FA22E8A

#include "BaseEffect.fxh"

struct VS_INPUT
{
    float4 Position : POSITION0;
    float4 Color : COLOR0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float4 Color : COLOR0;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float4 worldViewPos = TransformPositionToClip(input.Position);
    output.Position = ApplyTexelOffset(worldViewPos);
    output.Color = input.Color;

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    float3 color = input.Color.rgb * Material_Diffuse;
    float alpha = input.Color.a * Material_Opacity;
    clip(alpha - 0.01);
    
    // Alpha is intended to be multipled twice by opacity
    return float4(color, alpha * Material_Opacity);
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}