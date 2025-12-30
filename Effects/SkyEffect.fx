// SkyEffect
// 2BA9F71DF6B17F7E30630C8079588F10757B57CD4E4EC15878B11359EA6F62B7

#include "BaseEffect.fxh"

static const float DISTANCE_THRESHOLD = 1.0 / 84.0;

float3 CenterPosition;

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
    float FadeFactor : TEXCOORD1;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float4 worldViewPos = TransformPositionToClip(input.Position);
    output.Position = ApplyTexelOffset(worldViewPos);
    output.TexCoord = TransformTexCoord(input.TexCoord);

    float4 worldPos = TransformPositionToWorld(input.Position);
    float distanceFromCenter = abs(worldPos.y - CenterPosition.y);
    output.FadeFactor = 1.0 - min(pow(distanceFromCenter * DISTANCE_THRESHOLD, 2.0), 1.0);

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    float4 color = SAMPLE_TEXTURE(BaseTexture, input.TexCoord);
    color.r = color.a * Material_Opacity;
    color = color.rrrr * input.FadeFactor;
    return color;
}

technique TSM2
{
    pass P0
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}
