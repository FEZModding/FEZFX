// HwPlaneParticleEffect
// CC2E9D0C9242C774781649C5E33D80860918C8385A3DDC5AB4661C18E040BDBE

#include "BaseEffect.fxh"

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
    float4 InstancePositionPhi : TEXCOORD2;     // Position, Phi
    float4 InstanceSizeBirth : TEXCOORD3;       // SizeBirth
    float4 InstanceSpawnColor : TEXCOORD4;      // SpawnColor
};

struct VS_OUTPUT
{
    float2 TexCoord : TEXCOORD0;
    float4 SpawnColor : TEXCOORD1;
    float4 Position : POSITION;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float3 Position = input.InstancePositionPhi.xyz;
    float Phi = input.InstancePositionPhi.w;
    float3 SizeBirth = input.InstanceSizeBirth.xyz;
    float4 SpawnColor = input.InstanceSpawnColor;

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
        VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS_Pre();
    }
    
    pass Main
    {
        VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS_Main();
    }
}
