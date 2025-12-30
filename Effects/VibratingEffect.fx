// VibratingEffect
// F63DDAEB6F6B5B082029F62DCAA69C022A1471FF07008024719A3CABCCA3886C

#include "BaseEffect.fxh"

static const float3 FOG_COLOR = RGB(0x0F011B);

float Intensity;
float FogDensity;

struct VS_INPUT
{
    float4 Position : POSITION0;
    float4 Color : COLOR0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
    float FogFactor : TEXCOORD1;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float3 phase = Time * 50.0 * input.Color.yzx;
    phase.y = input.Color.y * TAU - phase.y;
    phase.xz = input.Color.xz * TAU + phase.xz;

    float4 vibratingPos;
    vibratingPos.x = sin(phase.y) * Intensity * input.Color.x * 0.125 + input.Position.x;
    vibratingPos.z = sin(phase.z) * Intensity * input.Color.y * 0.125 + input.Position.z;
    vibratingPos.y = sin(phase.x) * Intensity * input.Color.z * 0.75;
    vibratingPos.w = input.Position.w;

    float4 worldViewPos = TransformPositionToClip(vibratingPos);
    output.Position = ApplyTexelOffset(worldViewPos);
    output.TexCoord = 1.0;
    output.FogFactor = ApplyExponentialSquaredFog(worldViewPos.w, FogDensity);

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    float3 color = lerp(Material_Diffuse, FOG_COLOR, input.FogFactor);
    return float4(color, Material_Opacity);
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}