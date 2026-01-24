// HwInstancedDotEffect
// 5B9364A58BDEB204C85526A90BD1BDA009F941F22A33C9DD13F2AA80C0054EE8

#include "BaseEffect.fxh"

static const float3x3 TILT_MATRIX = float3x3(
    1.0 / sqrt(2.0),    1.0 / sqrt(3.0),    -1.0 / sqrt(6.0),
    0.0,                1.0 / sqrt(3.0),    2.0 / sqrt(6.0),
    1.0 / sqrt(2.0),    -1.0 / sqrt(3.0),   1.0 / sqrt(6.0)
);

float Theta;
float EightShapeStep;
float DistanceFactor;
float ImmobilityFactor;

struct VS_INPUT
{
    float4 Position : POSITION0;
    float4 Color : COLOR0;
    float4 Data : TEXCOORD2;
};

struct VS_OUTPUT
{
    float4 Color : TEXCOORD0;
    float4 Position : POSITION0;
};

float3 RotateAndProject(float4 position, float randomSeed)
{
    float s, c;
    sincos(Theta + randomSeed, s, c);
    float4x4 rotation = float4x4(
        c, 0, 0, s,
        0, 1, 0, 0,
        0, 0, 1, 0,
        -s, 0, 0, c
    );

    float4 transformed = mul(rotation, position);
    float wFactor = ((transformed.w + 1.0) / 3.0 + 0.5) * (1.0 / 3.0);
    float3 projected = transformed.xyz * wFactor;

    return projected;
}

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    // Color shift!
    float3 hsvColor = input.Color.rgb;
    hsvColor[0] += Theta / 10.0 + input.Data.w;
    float3 color = HSV_RGB(hsvColor[0], hsvColor[1], hsvColor[2]) * 0.35;

    // 4D rotate & project!
    float4 projectedPosition = float4(RotateAndProject(input.Position, input.Data.w), 1.0);

    // Scale!
    float s = 1.0 + sin(EightShapeStep * 4.0 / 3.0 + input.Data.w) * 0.2;
    float3 scale = lerp(1.0, s * DistanceFactor, ImmobilityFactor);
    projectedPosition.xyz *= scale;

    // Tilt!
    projectedPosition.xyz = mul(TILT_MATRIX, projectedPosition.xyz);

    // Offset!
    projectedPosition.xyz += input.Data.xyz;

    // Move around!
    float c;
    sincos(EightShapeStep + input.Data.w, s, c);
    projectedPosition.xy += float2(c, s) * ImmobilityFactor;

    float4 worldViewPos = TransformPositionToClip(projectedPosition);
    output.Position = ApplyTexelOffset(worldViewPos);
    output.Color = float4(color * Material_Diffuse, Material_Opacity);

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    return input.Color;
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS();
    }
}
