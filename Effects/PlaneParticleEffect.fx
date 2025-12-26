// PlaneParticleEffect
// 7DC84D4ABFEEEFF37A79FB1C4AD9DD6BDC187243DF68E3EFF0BA6207B95FBDB5

#include "BaseEffect.fxh"

float4x4 InstanceData[60];
float Fullbright;       // boolean
float Additive;         // boolean

texture BaseTexture;
sampler2D BaseSampler = sampler_state
{
    Texture = <BaseTexture>;
};

struct VS_INPUT
{
    float4 Position : POSITION;
    float2 TexCoord : TEXCOORD0;
    float InstanceIndex : TEXCOORD1;
};

struct VS_OUTPUT
{
    float4 Position : POSITION;
    float2 TexCoord : TEXCOORD0;
    float4 SpawnColor : TEXCOORD1;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    int index = trunc(input.InstanceIndex);
    float3 Position = InstanceData[index][0].xyz;
    float Phi = InstanceData[index][0].w;
    float3 SizeBirth = InstanceData[index][1].xyz;
    float4 SpawnColor = InstanceData[index][2];

    float3x3 basis = PhiToMatrix(Phi);
    float4x4 xform = CreateTransform(Position, basis, SizeBirth);
    float4 worldPos = mul(input.Position, xform);
    worldPos = ApplyEyeParallax(worldPos);

    float4 worldViewPos = TransformPositionToClip(worldPos);
    output.Position = ApplyTexelOffset(worldViewPos);
    output.TexCoord = input.TexCoord;
    output.SpawnColor = SpawnColor;

    return output;
}

float4 PS_Pre(VS_OUTPUT input) : COLOR0
{
    float4 texColor = tex2D(BaseSampler, input.TexCoord);

    float3 color;
    float alpha;
    if (Additive)
    {
        color = texColor.rgb * input.SpawnColor.rgb * Fullbright;
        alpha = 1.0;
    }
    else
    {
        color = DiffuseLight + (1.0 - DiffuseLight) * Fullbright;
        alpha = texColor.a * input.SpawnColor.a;
    }

    return float4(color * 0.5, alpha);
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    float4 texColor = tex2D(BaseSampler, input.TexCoord);

    float4 result = texColor * input.SpawnColor;
    ApplyAlphaTest(result.a);

    return result;
}

technique TSM2
{
    pass Pre
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS_Pre();
    }
    
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS_Main();
    }
}
