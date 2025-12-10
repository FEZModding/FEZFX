// LightingPostEffect
// AE3D5D93B0B2479B818BDE0123631CCB0288F7FFEE2DB8DE3641A35C67AA5D90

float2 TexelOffset;
float3 Fog_Color;
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
    
    output.Position.xy = (TexelOffset * input.Position.w) + input.Position.xy;
    output.Position.zw = input.Position.zw;
    
    return output;
}

float4 PS_Dawn(VS_OUTPUT input) : COLOR0
{
    float3 color = Fog_Color * DawnContribution * 0.2;
    
    return float4(color, 1.0);
}

float4 PS_Dusk_Multiply(VS_OUTPUT input) : COLOR0
{
    float scale = 0.2 * DuskContribution;
    float3 temp = (Fog_Color.zyx * 2.0) - 1.0;
    float3 color = (scale * temp.zyx) + 1.0;
    
    return float4(color, 1.0);
}

float4 PS_Dusk_Screen(VS_OUTPUT input) : COLOR0
{
    float3 adjusted = Fog_Color - 0.5;
    float3 doubled = saturate(adjusted + adjusted);
    float3 color = doubled * DuskContribution * 0.2;
    
    return float4(color, 1.0);
}

float4 PS_Night(VS_OUTPUT input) : COLOR0
{
    float maxComponent = max(max(Fog_Color.x, Fog_Color.y), Fog_Color.z);
    float3 normalized = (Fog_Color / maxComponent) - 1.0;
    float scale = 0.125 * NightContribution;
    float3 color = (scale * normalized) + 1.0;
    
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