// FarAwayEffect
// 6BD67ADFAF58B798C67FAA2C6112F91097CD1877399BE2A3C775FF59921128E9

#include "BaseEffect.fxh"

float ActualOpacity;

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

    float4 worldViewPos = TransformPositionToClip(input.Position);
    output.Position = ApplyTexelOffset(worldViewPos);
    output.TexCoord = input.TexCoord;

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    float4 texColor = SAMPLE_TEXTURE(BaseTexture, input.TexCoord);
    
    float3 color = lerp(Material_Diffuse, texColor.rgb, Material_Opacity);
    float alpha = texColor.a * ActualOpacity;
    ApplyAlphaTest(alpha);
    
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