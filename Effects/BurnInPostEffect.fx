// BurnInPostEffect
// 42F99AA09C24C293A44E519631A57B3DA30A358692D099026E04B4907DE07AD0

#include "BaseEffect.fxh"

float3 AcceptColor;

DECLARE_TEXTURE(NewFrameTexture);
DECLARE_TEXTURE(OldFrameTexture);

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
    float4 newFrame = SAMPLE_TEXTURE(NewFrameTexture, input.TexCoord);
    float4 oldFrame = SAMPLE_TEXTURE(OldFrameTexture, input.TexCoord);

    // Create multiplicative mask and square it for strong falloff
    float3 colorMatch = 1.0 - abs(newFrame.rgb - AcceptColor);
    float mask = pow(colorMatch.r * colorMatch.g * colorMatch.b, 2);

    // Blend: 25% of new matched color + 75% of old frame
    float3 newContribution = AcceptColor * mask * 0.25;
    float3 color = oldFrame.rgb * 0.75 + newContribution;

    return float4(color, 1.0);
}

technique TSM2
{
    pass P0
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}