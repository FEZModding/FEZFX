// LightingPostEffect
// AE3D5D93B0B2479B818BDE0123631CCB0288F7FFEE2DB8DE3641A35C67AA5D90

#include "BaseEffect.fxh"

static const float DAWN_FACTOR = 0.2;
static const float DUSK_FACTOR = 0.2;
static const float NIGHT_FACTOR = 0.125;

float DawnContribution;     // Non-zero from 02:00 to 06:00
float DuskContribution;     // Non-zero from 18:00 to 20:00
float NightContribution;    // Non-zero from 20:00 to 02:00

struct VS_INPUT
{
    float4 Position : POSITION0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    output.Position = ApplyTexelOffset(input.Position);

    return output;
}

float4 PS_Dawn(VS_OUTPUT input) : COLOR0
{
    float3 color = Fog_Color * DAWN_FACTOR * DawnContribution;
    return float4(color, 1.0);
}

float4 PS_Dusk_Multiply(VS_OUTPUT input) : COLOR0
{
    float3 color = lerp(1.0, Fog_Color * 2.0, DUSK_FACTOR * DuskContribution);
    return float4(color, 1.0);
}

float4 PS_Dusk_Screen(VS_OUTPUT input) : COLOR0
{
    float3 clamped = saturate((Fog_Color - 0.5) * 2.0);
    float3 color = clamped * DUSK_FACTOR * DuskContribution;
    return float4(color, 1.0);
}

float4 PS_Night(VS_OUTPUT input) : COLOR0
{
    float3 maxedFog = Fog_Color;
    maxedFog /= max(Fog_Color.r, max(Fog_Color.g, Fog_Color.b));
    float3 color = lerp(1.0, maxedFog, NIGHT_FACTOR * NightContribution);
    return float4(color, 1.0);
}

technique TSM2
{
    pass Dawn
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS_Dawn();
    }

    pass Dusk_Multiply
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS_Dusk_Multiply();
    }

    pass Dusk_Screen
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS_Dusk_Screen();
    }

    pass Night
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS_Night();
    }
}