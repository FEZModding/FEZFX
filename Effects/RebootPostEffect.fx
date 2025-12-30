// RebootPostEffect
// 8D85ED09059CC414C21C013FDD92E968705380AC2064E82556EDE2D440F7447D

#include "BaseEffect.fxh"

float4x4 PseudoWorldMatrix;

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

    float4 pseudoPos = mul(input.Position, PseudoWorldMatrix);
    output.Position = ApplyTexelOffset(pseudoPos);
    output.TexCoord = TransformTexCoord(input.TexCoord);

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    float4 texColor = SAMPLE_TEXTURE(BaseTexture, input.TexCoord);
    
    float3 color = texColor.rgb * Material_Diffuse;
    float alpha = texColor.a * Material_Opacity;
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