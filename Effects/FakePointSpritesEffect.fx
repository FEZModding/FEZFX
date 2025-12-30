// FakePointSpritesEffect
// 7F3881827B65EADDD2404E42BC6BCB297FD9D42C49135053BD76179128646E8B

#include "BaseEffect.fxh"

static const float4 FOG_COLOR = float4(0, 0, 0, 1);
static const float FOG_DENSITY = 0.00175;

float ViewScale;

DECLARE_TEXTURE(BaseTexture);

struct VS_INPUT
{
    float4 Position : POSITION;
    float4 Color : COLOR;
    float2 TexCoord : TEXCOORD;
    float2 BillboardOffset : TEXCOORD1;
};

struct VS_OUTPUT
{
    float4 Position : POSITION;
    float4 Color : COLOR;
    float2 TexCoord : TEXCOORD0;
    float FogFactor : TEXCOORD1;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float4 worldViewPos = TransformPositionToClip(input.Position);
    float2 screenOffset = (-TexelOffset * ViewScale) * input.BillboardOffset * worldViewPos.w;
    output.Position = ApplyTexelOffset(worldViewPos, screenOffset * 2.0);

    output.Color = input.Color * Material_Opacity * input.Color.a;
    output.TexCoord = input.TexCoord;
    output.FogFactor = ApplyExponentialSquaredFog(worldViewPos.w, FOG_DENSITY);

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    float4 texColor = SAMPLE_TEXTURE(BaseTexture, input.TexCoord);
    float4 fogColor = lerp(input.Color, FOG_COLOR, input.FogFactor);
    return texColor * fogColor;
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}
