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
    float3 InstanceTranslation : TEXCOORD2;
    float4 InstanceColor : TEXCOORD3;
    float3 InstanceScale : TEXCOORD4;
    float4 InstanceTexture : TEXCOORD5;
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

    float4x4 rotation = (Billboard) ? CameraRotation : MATRIX_IDENTITY;
    float4x4 xform = CreateTransform(input.InstanceTranslation, (float3x3)rotation, input.InstanceScale);
    float4 worldPos = mul(input.Position, xform);

    float4 worldViewPos = TransformPositionToClip(worldPos);
    output.Position = ApplyTexelOffset(worldViewPos);
    output.Color = (Billboard) ? 1.0 : input.InstanceColor;
    output.TexCoord = input.TexCoord * input.InstanceTexture.zw + input.InstanceTexture.xy;

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
        VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS();
    }
}
