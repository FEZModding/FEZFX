// InstancedBlackHoleEffect
// 114B5D3E88D90F7E4DD43E17063685643CB380F20ED4982A0F9F479C67763477

#include "BaseEffect.fxh"

float4x4 InstanceData[60];
float IsTextureEnabled;     // boolean

DECLARE_TEXTURE(BaseTexture);

struct VS_INPUT
{
    float4 Position : POSITION;
    float2 TexCoord : TEXCOORD;
    float InstanceIndex : TEXCOORD1;
};

struct VS_OUTPUT
{
    float2 TexCoord : TEXCOORD0;
    float3 Color : TEXCOORD1;
    float4 Position : POSITION;
    float InstanceIndex : TEXCOORD2;
};

VS_OUTPUT VS_Body(VS_INPUT input)
{
    VS_OUTPUT output;

    int index = floor(input.InstanceIndex);
    float4 InstancePosition = InstanceData[index][0];
    float4 InstanceDiffuse = InstanceData[index][1];

    float4x4 xform = CreateTransform(InstancePosition);
    float4 worldPos = mul(input.Position, xform);

    float4 worldViewPos = TransformPositionToClip(worldPos);
    output.Position = ApplyTexelOffset(worldViewPos);
    
    output.TexCoord = 0;
    output.Color = InstanceDiffuse.rgb;
    output.InstanceIndex = input.InstanceIndex;

    return output;
}

VS_OUTPUT VS_Fringe(VS_INPUT input)
{
    VS_OUTPUT output;

    int index = floor(input.InstanceIndex);
    float3 InstancePosition = InstanceData[index][0].xyz;
    float3 InstanceDiffuse = InstanceData[index][1].xyz;
    float2 InstanceTextureOffset = InstanceData[index][2].xy;
    float2 InstanceTextureScale = InstanceData[index][3].xy;
    
    float4x4 xform = CreateTransform(InstancePosition);
    float4 worldPos = mul(input.Position, xform);

    float4 worldViewPos = TransformPositionToClip(worldPos);
    output.Position = ApplyTexelOffset(worldViewPos);

    float3x3 xform2D = CreateTransform2D(InstanceTextureOffset, InstanceTextureScale);
    output.TexCoord = TransformTexCoord(input.TexCoord, xform2D);
    output.Color = InstanceDiffuse;
    output.InstanceIndex = input.InstanceIndex;
    
    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    float4 color;
    
    if (IsTextureEnabled)
    {
        float4 texColor = SAMPLE_TEXTURE(BaseTexture, input.TexCoord);
        color.rgb = texColor.rgb * input.Color;
        color.a = texColor.a;
        ApplyAlphaTest(color.a);
    }
    else
    {
        color = float4(input.Color, 1.0);
    }
    
    return color;
}

technique TSM2
{
    pass Body
    {
        VertexShader = compile vs_2_0 VS_Body();
        PixelShader = compile ps_2_0 PS();
    }

    pass Fringe
    {
        VertexShader = compile vs_2_0 VS_Fringe();
        PixelShader = compile ps_2_0 PS();
    }
}
