// SkyBackEffect
// D2D752E06F61467200315E64D415EE80D8C129BB4B595E0957C343AA2F105F3A

#include "BaseEffect.fxh"

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
    output.TexCoord = TransformTexCoord(input.TexCoord);

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    float4 texColor = SAMPLE_TEXTURE(BaseTexture, input.TexCoord);
    return float4(texColor.rgb, 1.0);
}

technique TSM2
{
    pass P0
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}