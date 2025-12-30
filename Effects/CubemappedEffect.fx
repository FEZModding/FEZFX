// CubemappedEffect
// AD296A9BA42B7803025C1F7CD6A009F707EA411D49C6E6A5476E178D1F7C6273

#include "BaseEffect.fxh"

float ForceShading;     // boolean

DECLARE_TEXTURE(CubemapTexture);

struct VS_INPUT
{
    float4 Position : POSITION0;
    float3 Normal : NORMAL0;
    float2 TexCoord : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float3 Normal : TEXCOORD0;
    float FogFactor : TEXCOORD1;
    float2 TexCoord : TEXCOORD2;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float4 worldViewPos = TransformPositionToClip(input.Position);
    output.Position = ApplyTexelOffset(worldViewPos);
    output.Normal = TransformNormalToWorld(input.Normal);
    output.FogFactor = ApplyFog(worldViewPos.w, Fog_Density);
    output.TexCoord = input.TexCoord;

    return output;
}

float4 PS_Pre(VS_OUTPUT input) : COLOR0
{
    float4 texColor = SAMPLE_TEXTURE(CubemapTexture, input.TexCoord);
    float3 color = CalculateLighting(input.Normal, texColor.a);

    return float4(color * 0.5, Material_Opacity);
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    float4 texColor = SAMPLE_TEXTURE(CubemapTexture, input.TexCoord);
    
    float3 color = texColor.rgb * Material_Diffuse;
    if (ForceShading)
    {
        color *= CalculateLighting(input.Normal, texColor.a);
    }
    color = lerp(color, Fog_Color, input.FogFactor);

    return float4(color, Material_Opacity);
}

technique TSM2
{
    pass Pre
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS_Pre();
    }

    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS_Main();
    }
}
