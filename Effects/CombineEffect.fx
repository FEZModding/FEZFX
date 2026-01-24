// CombineEffect
// EC7FD1032031BC9352447B5964B635E282D7E9B94CEDA61070B909B99C62C688

#include "BaseEffect.fxh"

float3x3 LeftFilter;
float3x3 RightFilter;
float RedGamma;

DECLARE_TEXTURE(LeftTexture);
DECLARE_TEXTURE(RightTexture);

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
    float4 left = SAMPLE_TEXTURE(LeftTexture, input.TexCoord);
    float4 right = SAMPLE_TEXTURE(RightTexture, input.TexCoord);

    float3 color = mul(LeftFilter, left.rgb) + mul(RightFilter, right.rgb);
    color.r = pow(abs(color.r), 1.0 / RedGamma);
    float alpha = max(left.a, right.a);

    return float4(color, alpha);
}

technique ShaderModel2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}