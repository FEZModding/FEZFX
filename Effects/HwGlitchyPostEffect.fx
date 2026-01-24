// HwGlitchyPostEffect
// 80DFFEDBAC9BF6BF013BD26BB081069CD2508B5D355EC23849F9F618ACB75473

#include "BaseEffect.fxh"

static const float2 VERTEX_SCALE = float2(53.333 / 2.0, 30.0 / 2.0);
static const float TEXEL_SCALE = 42.666;

DECLARE_TEXTURE(GlitchTexture);

struct VS_INPUT
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
    float4 InstanceData0 : TEXCOORD2;   // Row 1 : Position (xy), Scale (zw)
    float4 InstanceData1 : TEXCOORD3;   // Row 2 : InvertR/G/B (xyz), ClipDark (w)
    float4 InstanceData2 : TEXCOORD4;   // Row 3 : FlipR/G/B (xyz), Unused (w)
    float4 InstanceData3 : TEXCOORD5;   // Row 4 : TcOffset (xy), Unused (z), Hide (w)
};

struct VS_OUTPUT
{
    float2 TexCoord : TEXCOORD0;
    float4 InvertRGB_ClipDark : TEXCOORD1;
    float3 FlipRGB : TEXCOORD2;
    float4 Position : POSITION0;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float3 position = input.Position;
    position.xy = position.xy * input.InstanceData0.zw + input.InstanceData0.xy;
    position.xy = position.xy / VERTEX_SCALE - 1.0;
    output.Position = float4(position, 1.0) * !input.InstanceData3.w;

    float2 texCoord = input.TexCoord;
    texCoord *= input.InstanceData0.zw / TEXEL_SCALE;
    texCoord += input.InstanceData3.xy;
    texCoord.y += 1.0 - input.InstanceData0.w / TEXEL_SCALE;
    output.TexCoord = texCoord;

    output.InvertRGB_ClipDark = input.InstanceData1;
    output.FlipRGB = input.InstanceData2.xyz;

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    float4 color = SAMPLE_TEXTURE(GlitchTexture, input.TexCoord);
    
    if (input.InvertRGB_ClipDark.x != 0.0) 
    {
        color.rg = color.gr;
    }
    
    if (input.InvertRGB_ClipDark.y != 0.0) 
    {
        color.gb = color.bg;
    }
    
    if (input.InvertRGB_ClipDark.z != 0.0) 
    {
        color.rb = color.br;
    }
    
    if (input.FlipRGB.x != 0.0)
    {
        color.r = 1.0 - color.r;
    }
    
    if (input.FlipRGB.y != 0.0)
    {
        color.g = 1.0 - color.g;
    }
    
    if (input.FlipRGB.z != 0.0)
    {
        color.b = 1.0 - color.b;
    }
    
    float luminance = dot(color.rgb, 1.0 / 3.0);
    float l = (input.InvertRGB_ClipDark.w != 0.0) ? luminance : (1.0 - luminance);
    clip(l + color.a - 1.5);
    
    return float4(color.rgb, 1.0);
}

technique TSM2
{
    pass P0
    {
        VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS();
    }
}
