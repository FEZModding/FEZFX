// InstancedDotEffect
// 10D2DCA87CBA95704DA5676D0049E03CEC15582FD44B342E0F487665254336B1

#include "BaseEffect.fxh"

static const float3x3 ISOMETRIC_MATRIX = float3x3(
    1.0 / sqrt(2.0),    0,                  1.0 / sqrt(2.0),
    1.0 / sqrt(3.0),    1.0 / sqrt(3.0),    -1.0 / sqrt(3.0),
    -1.0 / sqrt(6.0),   2.0 / sqrt(6.0),    1.0 / sqrt(6.0)
);

float4 InstanceData[225];
float Theta;
float EightShapeStep;
float DistanceFactor;
float ImmobilityFactor;

struct VS_INPUT
{
    float4 Position : POSITION0;
    float4 Color : COLOR0;
    float InstanceIndex : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4 Color : TEXCOORD0;
    float4 Position : POSITION0;
};

VS_OUTPUT VS_Main(VS_INPUT input)
{
    VS_OUTPUT output;

    int index = trunc(input.InstanceIndex);
    float3 Offset = InstanceData[index].xyz;
    float Rotation = InstanceData[index].w;

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
        VertexShader = compile vs_2_0 VS_Main();
        PixelShader = compile ps_2_0 PS_Main();
    }
}
