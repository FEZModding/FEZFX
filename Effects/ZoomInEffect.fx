// ZoomInEffect
// 41C180564DAD1048840561B6365431F3A6B19468E6A0549F8D0A667B8611FBE4

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

    output.Position = ApplyTexelOffset(input.Position);
    output.TexCoord = TransformTexCoord(input.TexCoord);

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    float2 texCoord = saturate(input.TexCoord);     // Clamps in [0, 1] range
    float4 texColor = SAMPLE_TEXTURE(BaseTexture, texCoord);

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