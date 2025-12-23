// ProjectedNodeEffect
// 2E32EF0C6F1391B858E068D8A1CA520A4605641726F6F3721EF96E1EB9450FDB

#include "BaseEffect.fxh"

static const float3 GRAY_COLOR = float3(0.5, 0.5, 0.5);
static const float3 DARK_COLOR = RGB(0x404040);
static const float3 GOLD_COLOR = RGB(0xFFBE24);

float2 ViewportSize;
float2 TextureSize;
float PixelsPerTrixel;
bool NoTexture;
bool Complete;
float3 CubeOffset;

texture BaseTexture;
sampler2D BaseSampler = sampler_state
{
    Texture = <BaseTexture>;
};

struct VS_INPUT
{
    float4 Position : POSITION0;
    float4 Normal : NORMAL0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float4 Normal : TEXCOORD0;
    float4 WorldViewPos : TEXCOORD1;
    float4 CubePos : TEXCOORD2;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    output.Normal = TransformNormalToWorld(input.Normal);
    output.CubePos = TransformWorldToClip(float4(CubeOffset, 1.0));
    output.WorldViewPos = TransformPositionToClip(input.Position);
    output.Position = output.WorldViewPos;

    return output;
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    float3 normal = input.Normal.xyz;
    float invAmbient = 1.0 - BaseAmbient;
    float normalDot = saturate(dot(normal, 1.0));
    float lighting = normalDot * invAmbient + saturate(BaseAmbient);

    float faceLight = lighting;
    if (normal.x < 0.01) // Negative X face
    {
        float absX = abs(normal.x) * invAmbient;
        faceLight = lighting - (absX * 0.2);
    }
    if (normal.z >= -0.01) // Positive Z face
    {
        float absZ = abs(normal.z) * invAmbient;
        faceLight = lighting + (absZ * 0.6);
    }
    if (normal.x >= -0.01) // Positive X face
    {
        float absX = abs(normal.x) * invAmbient;
        faceLight = faceLight + (absX * 0.4);
    }
    if (normal.y < 0.01) // Negative Y face
    {
        float absY = abs(normal.y) * invAmbient;
        faceLight = faceLight - (absY * 0.1);
    }
    
    faceLight = saturate(faceLight);
    float lightPower = pow(faceLight, 0.75);

    // Project CubePos
    float2 cubeProj = input.CubePos.xy / input.CubePos.w;
    cubeProj.y = -cubeProj.y;
    cubeProj *= PixelsPerTrixel;
    
    // Project WorldViewPos
    float2 worldProj = input.WorldViewPos.xy / input.WorldViewPos.w;
    worldProj.y = -worldProj.y;

    // Calculate texture coord from projected positions
    float2 texCoord = (worldProj * PixelsPerTrixel) - cubeProj;
    texCoord *= (1.0 / TextureSize) * ViewportSize;
    texCoord = texCoord * 0.166667 + 0.5;
    texCoord += 0.5 / ViewportSize;

    float3 color = tex2D(BaseSampler, texCoord).rgb;
    if (NoTexture)
    {
        color = DARK_COLOR;
    }
    if (Complete)
    {
        color *= GOLD_COLOR;
    }
    color *= lightPower;

    return float4(color, Material_Opacity);
}

float4 PS_Pre(VS_OUTPUT input) : COLOR0
{
    clip(Material_Opacity - 0.00999999978);
    return float4(GRAY_COLOR, 1.0);
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS_Main();
    }

    pass Pre
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS_Pre();
    }
}
