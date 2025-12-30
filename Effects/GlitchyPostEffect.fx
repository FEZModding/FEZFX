// GlitchyPostEffect
// 2B68A10233805944DD6564BDE029B9641E7752BA24BFE829C1D8ABF899C20D52

#include "BaseEffect.fxh"

static const float2 VERTEX_SCALE = float2(3.0 / 80.0, 1.0 / 15.0);
static const float TEXEL_SCALE = 0.0234378669;

float4x4 InstanceData[60];

DECLARE_TEXTURE(GlitchTexture);

struct VS_INPUT
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
    float InstanceIndex : TEXCOORD1;
};

struct VS_OUTPUT
{
    float2 TexCoord : TEXCOORD0;
    float4 Flags1 : TEXCOORD1;    // RGB swapping, Alpha test
    float3 Flags2 : TEXCOORD2;    // RGB inversion
    float4 Position : POSITION0;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    int index = trunc(input.InstanceIndex);
    float4 InstanceData0 = InstanceData[index][0];   // Position, UV scale
    float4 InstanceData1 = InstanceData[index][1];   // RGB swapping, Alpha test
    float4 InstanceData2 = InstanceData[index][2];   // RGB inversion
    float4 InstanceData3 = InstanceData[index][3];   // UV offset, Disabled

    float3 position = input.Position;
    position.xy = position.xy * InstanceData0.zw + InstanceData0.xy;
    position.xy = position.xy * VERTEX_SCALE - 1.0;
    output.Position = float4(position, 1.0) * !InstanceData3.w;

    float2 texCoord = input.TexCoord;
    texCoord *= InstanceData0.zw * TEXEL_SCALE;
    texCoord += InstanceData3.xy;
    texCoord.y += 1.0 - InstanceData0.w * TEXEL_SCALE;
    output.TexCoord = texCoord;

    output.Flags1 = InstanceData1;
    output.Flags2 = InstanceData2.xyz;

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    float4 texColor = SAMPLE_TEXTURE(GlitchTexture, input.TexCoord);

    float3 color = texColor.rgb;
    if (input.Flags1.x)
    {
        color.rg = color.gr;
    }

    if (input.Flags1.y)
    {
        color.gb = color.bg;
    }
    
    if (input.Flags1.z)
    {
        color.rb = color.br;
    }
    
    if (input.Flags2.x)
    {
        color.r = 1.0 - color.r;
    }
    
    if (input.Flags2.y)
    {
        color.g = 1.0 - color.g;
    }

    if (input.Flags2.z)
    {
        color.b = 1.0 - color.b;
    }

    float invAlpha = 1.0 - texColor.a;
    float luminance = dot(color, 1.0 / 3.0);
    if (input.Flags1.w)
    {
        clip(0.5 - invAlpha - luminance);
        clip(luminance - invAlpha - 0.5);
    }

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
