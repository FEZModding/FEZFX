// InstancedMapEffect
// 6F8EC2821399F1EFF02414B6C388A3D83713560588F2C5BDA0AEB0153A36DA3A

#include "BaseEffect.fxh"

// Row 1 : Position (xyz), Unused (w)
// Row 2 : Color (xyz), Opacity (w)
// Row 3 : Scale (xyz), Unused (w)
// Row 4 : TC Offset (xy), TC Scale (zw)
float4x4 InstanceData[58];
float4x4 CameraRotation;
float Billboard;        // boolean

DECLARE_TEXTURE(BaseTexture);

struct VS_INPUT
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
    float InstanceIndex : TEXCOORD1;
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
    float4x4 data = InstanceData[(int)input.InstanceIndex];

    float4x4 rotation = (Billboard != 0.0) ? CameraRotation : MATRIX_IDENTITY;
    float4x4 xform = CreateTransform(data[0].xyz, (float3x3)rotation, data[2].xyz);
    float4 worldPos = mul(input.Position, xform);

    float4 worldViewPos = TransformPositionToClip(worldPos);
    output.Position = ApplyTexelOffset(worldViewPos);
    
    float3 color = (Billboard != 0.0) ? 1.0 : data[1].xyz;
    output.Color = float4(color, data[1].w);
    output.TexCoord = input.TexCoord * data[3].zw + data[3].xy;

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
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}
