// CloudsEffect
// 360896CC8C8762B21C1A4CE175D88F01E477E5BAC22E8DB8DD1A308EB25B3312

#include "Common.fxh"

float Material_Opacity;
float4x4 Matrices_WorldViewProjection;
float3x3 Matrices_Texture;
float2 TexelOffset;
texture BaseTexture;

sampler2D BaseSampler = sampler_state
{
    Texture = <BaseTexture>;
};

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

    output.Position = mul(input.Position, Matrices_WorldViewProjection);
    output.Position.xy += TexelOffset * output.Position.w;

    float3 texCoord = float3(input.TexCoord, 1.0);
    output.TexCoord = mul(texCoord, Matrices_Texture).xy;

    return output;
}

float4 PS_P0(VS_OUTPUT input) : COLOR0
{
    float4 texColor = tex2D(BaseSampler, input.TexCoord);
    float alpha = texColor.a * Material_Opacity;
    clip(alpha - ALPHA_THRESHOLD);

    return float4(alpha, alpha, alpha, alpha);
}

technique TSM2
{
    pass P0
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS_P0();
    }
}