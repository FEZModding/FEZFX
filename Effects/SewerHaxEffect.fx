// SewerHaxEffect
// 794B81B88AEAFD49057C4E8CE8A7770B9BA4A0775C194B505162593EF4BC040F

#include "BaseEffect.fxh"

static const float3 DARK_COLOR = RGB(0x204631);
static const float3 LIGHT_COLOR = RGB(0x527F39);

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
    output.TexCoord = input.TexCoord;

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    float4 texColor = SAMPLE_TEXTURE(BaseTexture, input.TexCoord);

    float3 color = (texColor.r == 0.0) ? DARK_COLOR : LIGHT_COLOR;
    return float4(color, 1.0);
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}