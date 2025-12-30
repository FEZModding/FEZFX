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
    float4 leftColor = SAMPLE_TEXTURE(LeftTexture, input.TexCoord);
    float4 rightColor = SAMPLE_TEXTURE(RightTexture, input.TexCoord);

    float3 leftFiltered = mul(LeftFilter, leftColor.rgb);
    float3 rightFiltered = mul(RightFilter, rightColor.rgb);

    float3 combined = leftFiltered + rightFiltered;
    float redGammaCorrected = pow(abs(combined.r), 1.0 / RedGamma);
    float alpha = max(leftColor.a, rightColor.a);

    return float4(redGammaCorrected, combined.gb, alpha);
}

technique ShaderModel2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}