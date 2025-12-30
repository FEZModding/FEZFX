// LightmapEffect
// 0F1710E96C68066CEB9D0F033D365109C9F0F144B91244E7DEFB8E0749B64FF5

#include "BaseEffect.fxh"

float ShadowPass;       // boolean

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

    output.Position = ApplyTexelOffset(input.Position);
    output.TexCoord = TransformTexCoord(input.TexCoord);

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    float4 texColor = SAMPLE_TEXTURE(BaseTexture, input.TexCoord);

    float3 color = (ShadowPass)
        ? saturate(texColor.rgb * 2.0)
        : saturate(texColor.rgb - 0.5) * 4.0 + 1.0;

    return float4(color, 1.0);
}

technique TSM2
{
    pass Shadows
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}