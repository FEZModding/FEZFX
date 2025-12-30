// FoamEffect
// D5A74AD87A7BC194B7BE3F243B75D1A20F24CA7F5372C505A052D91B1A43EB15

#include "BaseEffect.fxh"

float TimeAccumulator;
float ShoreTotalWidth;
float ScreenCenterSide;
float IsEmerged;        // boolean
float IsWobbling;       // boolean

struct VS_INPUT
{
    float4 Position : POSITION0;
    float4 Normal : NORMAL0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    // Calculate the offset to draw the foam line.
    float offset = input.Normal.x - ScreenCenterSide;
    offset += sign(offset) * ShoreTotalWidth * 0.5;
    offset = trunc(offset / ShoreTotalWidth);
    offset = input.Normal.x - (offset * ShoreTotalWidth);

    // Calculate small or large wave height
    float wave = cos(offset * 2.0 + TimeAccumulator * 3.0);
    float denominator = 3.0 - abs(wave);
    float small = denominator / 3.0;
    float large = 3.0 / denominator;
    
    // Select final wave height
    float waveHeight = (sign(wave) > 0.0)
        ? ((IsEmerged) ? large : small)
        : ((IsEmerged) ? small : large);

    float2 wavePos;
    wavePos.x = offset + input.Position.x;
    wavePos.y = waveHeight * input.Position.y;

    float4 position = input.Position;
    position.xy = IsWobbling ? wavePos.xy : input.Position.xy;
    
    float4 worldViewPos = TransformPositionToClip(position);
    output.Position = ApplyTexelOffset(worldViewPos);

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    return float4(Material_Diffuse, Material_Opacity);
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}
