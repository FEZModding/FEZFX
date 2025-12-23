// HwInstancedMapEffect
// 8A75D00EA18901A9F3098040A5726370E74624EDA527E6526E344A075E8D1FF6

#include "BaseEffect.fxh"

float4x4 CameraRotation;
float Billboard;

texture BaseTexture;
sampler2D BaseSampler = sampler_state
{
    Texture = <BaseTexture>;
};

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
    float3x3 basis = float3x3(
        rotation[0].xyz * input.InstanceScale.x,
        rotation[1].xyz * input.InstanceScale.y,
        rotation[2].xyz * input.InstanceScale.z
    );
    
    float3 transform = mul(input.Position, basis);
    float4 worldPos = float4(transform + input.InstanceTranslation, input.Position.w);

    float4 clipPos = TransformPositionToClip(worldPos);
    output.Position = ApplyTexelOffset(clipPos);
    output.Color = (Billboard) ? 1.0 : input.InstanceColor;
    output.TexCoord = input.TexCoord * input.InstanceTexture.zw + input.InstanceTexture.xy;

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    float alpha = input.Color.a;
    clip(alpha - 0.01);
    
    float4 color = (Billboard) ? tex2D(BaseSampler, input.TexCoord) : 1.0;
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
