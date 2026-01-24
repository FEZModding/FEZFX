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
    float4 Color : TEXCOORD0;
    float Fog : TEXCOORD1;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float sineY = sin(input.Color.r * TAU + Time * 50.0 * input.Color.g) * Intensity * 0.75 * input.Color.b;
	float sineX = sin(input.Color.g * TAU - Time * 50.0 * input.Color.b) * Intensity * 0.125 * input.Color.r;
	float sineZ = sin(input.Color.b * TAU + Time * 50.0 * input.Color.r) * Intensity * 0.125 * input.Color.g;
    
    float4 position;
    position.x = input.Position.x + sineX;
    position.y = sineY;
    position.z = input.Position.z + sineZ;
    position.w = input.Position.w;

    float4 worldViewPos = TransformPositionToClip(position);
    output.Position = ApplyTexelOffset(worldViewPos);
    output.Fog = saturate(1.0 - Exp2Fog(output.Position.w, FogDensity));
    output.Color = 1.0;

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    float3 color = input.Color.rgb * Material_Diffuse;
    float alpha = input.Color.a * Material_Opacity;
    
    color = lerp(color, FOG_COLOR, input.Fog);
    return float4(color, alpha);
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}