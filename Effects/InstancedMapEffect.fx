// InstancedMapEffect
// 6F8EC2821399F1EFF02414B6C388A3D83713560588F2C5BDA0AEB0153A36DA3A

#include "BaseEffect.fxh"

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

    int index = trunc(input.InstanceIndex);
    float3 InstanceTranslation = InstanceData[index][0].xyz;
    float4 InstanceColor = InstanceData[index][1];
    float3 InstanceScale = InstanceData[index][2].xyz;
    float4 InstanceTexture = InstanceData[index][3];

    float4x4 rotation = (Billboard) ? CameraRotation : MATRIX_IDENTITY;
    float4x4 xform = CreateTransform(InstanceTranslation, (float3x3)rotation, InstanceScale);
    float4 worldPos = mul(input.Position, xform);

    float4 worldViewPos = TransformPositionToClip(worldPos);
    output.Position = ApplyTexelOffset(worldViewPos);
    output.Color = (Billboard) ? 1.0 : InstanceColor;
    output.TexCoord = input.TexCoord * InstanceTexture.zw + InstanceTexture.xy;

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    clip(input.Color.a - 0.01);

    float4 color = (Billboard) ? SAMPLE_TEXTURE(BaseTexture, input.TexCoord) : 1.0;
    return color * input.Color;
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}
