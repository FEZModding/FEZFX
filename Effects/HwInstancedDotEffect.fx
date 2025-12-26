// HwInstancedDotEffect
// 5B9364A58BDEB204C85526A90BD1BDA009F941F22A33C9DD13F2AA80C0054EE8

#include "BaseEffect.fxh"

static const float3x3 ISOMETRIC_MATRIX = float3x3(
    1.0 / sqrt(2.0),    0,                  1.0 / sqrt(2.0),
    1.0 / sqrt(3.0),    1.0 / sqrt(3.0),    -1.0 / sqrt(3.0),
    -1.0 / sqrt(6.0),   2.0 / sqrt(6.0),    1.0 / sqrt(6.0)
);

float Theta;
float EightShapeStep;
float DistanceFactor;
float ImmobilityFactor;

struct VS_INPUT
{
    float4 Position : POSITION0;
    float4 Color : COLOR0;
    float4 InstanceData : TEXCOORD2;    // Grid Offset, Rotation
};

struct VS_OUTPUT
{
    float4 Color : TEXCOORD0;
    float4 Position : POSITION0;
};

VS_OUTPUT VS_Main(VS_INPUT input)
{
    VS_OUTPUT output;

    float3 Offset = input.InstanceData.xyz;
    float Rotation = input.InstanceData.w;

    float s, c;
    sincos(Theta + Rotation, s, c);
    
    float rotatedX = input.Position.x * c - input.Position.w * s;
    float rotatedW = input.Position.x * s + input.Position.w * c;
    float scale = ((rotatedW + 1.0) / 3.0 + 0.5) / 3.0;
    float3 scaledPos = scale * float3(rotatedX, input.Position.yz);

    float distanceOsc = sin(EightShapeStep * (4.0 / 3.0) + Rotation) * 0.2 + 1.0;
    scaledPos *= ImmobilityFactor * (distanceOsc * DistanceFactor - 1.0) + 1.0;
    
    float4 worldPos = float4(mul(scaledPos, ISOMETRIC_MATRIX) + Offset, 1.0);
    sincos(EightShapeStep + Rotation, s, c);
    worldPos.xy += float2(c, s) * ImmobilityFactor;

    float4 worldViewPos = TransformPositionToClip(worldPos);
    output.Position = ApplyTexelOffset(worldViewPos);

    float hue = frac(Theta * 0.1 + Rotation + input.Color.x);
    float saturation = input.Color.y;
    float value = input.Color.z;
    
    float3 color = HSV_RGB(hue, saturation, value);
    output.Color.rgb = color * Material_Diffuse * 0.35;
    output.Color.a = Material_Opacity;

    return output;
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    return input.Color;
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_3_0 VS_Main();
        PixelShader = compile ps_3_0 PS_Main();
    }
}
