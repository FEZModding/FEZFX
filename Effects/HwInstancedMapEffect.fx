// HwInstancedMapEffect
// 8A75D00EA18901A9F3098040A5726370E74624EDA527E6526E344A075E8D1FF6

#include "BaseEffect.fxh"

float4x4 CameraRotation;
float Billboard;        // boolean

DECLARE_TEXTURE(BaseTexture);

struct VS_INPUT
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
    float3 InstanceData0 : TEXCOORD2;   // Row 1 : Position (xyz), Unused (w)
    float4 InstanceData1 : TEXCOORD3;   // Row 2 : Color (xyz), Opacity (w)
    float3 InstanceData2 : TEXCOORD4;   // Row 3 : Scale (xyz), Unused (w)
    float4 InstanceData3 : TEXCOORD5;   // Row 4 : TC Offset (xy), TC Scale (zw)
};

struct VS_OUTPUT
{
    float4 Color : TEXCOORD0;
    float2 TexCoord : TEXCOORD1;
    float4 Position : POSITION0;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float4x4 rotation = (Billboard != 0.0) ? CameraRotation : MATRIX_IDENTITY;
    float4x4 xform = CreateTransform(input.InstanceData0, (float3x3)rotation, input.InstanceData2);
    float4 worldPos = mul(input.Position, xform);

    float4 worldViewPos = TransformPositionToClip(worldPos);
    output.Position = ApplyTexelOffset(worldViewPos);

    float3 color = (Billboard != 0.0) ? 1.0 : input.InstanceData1.xyz;
    output.Color = float4(color, input.InstanceData1.w);
    output.TexCoord = input.TexCoord * input.InstanceData3.zw + input.InstanceData3.xy;

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    clip(input.Color.a - 0.01);
    float4 color = (Billboard != 0.0)
        ? SAMPLE_TEXTURE(BaseTexture, input.TexCoord)
        : 1.0;
    return input.Color * color;
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS();
    }
}
