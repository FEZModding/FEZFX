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
    float3 InstanceData : NORMAL0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float4 position = input.Position;
    if (IsWobbling != 0.0)
    {
        float stripOffset = input.InstanceData.x;

        float fits;
        float dist = stripOffset - ScreenCenterSide;
        modf((dist + sign(dist) * (ShoreTotalWidth / 2.0)) / ShoreTotalWidth, fits);
        stripOffset -= fits * ShoreTotalWidth;

        float dY = sin(stripOffset * 2.0 + TimeAccumulator * 3.0);
        float scaleNorD = abs(dY);

        float vScale;
        if (IsEmerged != 0.0)
        {
            vScale = sign(dY) != 1.0
                ? 3.0 / (3.0 - scaleNorD)
                : (3.0 - scaleNorD) / 3.0;
        }
        else
        {
            vScale = sign(dY) == 1.0
                ? 3.0 / (3.0 - scaleNorD)
                : (3.0 - scaleNorD) / 3.0;
        }

        position.y *= vScale;
        position.x += stripOffset;
    }
    
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
