// HwInstancedBlackHoleEffect
// 801A7029BD7964B684FAD7CFDBE914E067329F215DC8D9F65BC39E4E0A311239

#include "BaseEffect.fxh"

float IsTextureEnabled;     // boolean

DECLARE_TEXTURE(BaseTexture);

struct VS_INPUT
{
    float4 Position : POSITION;
    float2 TexCoord : TEXCOORD;
    float3 InstancePosition : TEXCOORD2;
    float3 InstanceDiffuse : TEXCOORD3;
    float2 InstanceTextureOffset : TEXCOORD4;
    float2 InstanceTextureScale : TEXCOORD5;
};

struct VS_OUTPUT
{
    float2 TexCoord : TEXCOORD0;
    float3 Color : TEXCOORD1;
    float4 Position : POSITION;
};

VS_OUTPUT VS_Body(VS_INPUT input)
{
    VS_OUTPUT output;

    float4x4 xform = CreateTransform(input.InstancePosition);
    float4 worldPos = mul(input.Position, xform);

    float4 worldViewPos = TransformPositionToClip(worldPos);
    output.Position = ApplyTexelOffset(worldViewPos);
    
    output.TexCoord = 0;
    output.Color = input.InstanceDiffuse;

    return output;
}

VS_OUTPUT VS_Fringe(VS_INPUT input)
{
    VS_OUTPUT output;

    float4x4 xform = CreateTransform(input.InstancePosition);
    float4 worldPos = mul(input.Position, xform);

    float4 worldViewPos = TransformPositionToClip(worldPos);
    output.Position = ApplyTexelOffset(worldViewPos);

    float3x3 xform2D = CreateTransform2D(input.InstanceTextureOffset, input.InstanceTextureScale);
    output.TexCoord = TransformTexCoord(input.TexCoord, xform2D);
    output.Color = input.InstanceDiffuse;

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
        VertexShader = compile vs_3_0 VS_Body();
        PixelShader = compile ps_3_0 PS();
    }

    pass Fringe
    {
        VertexShader = compile vs_3_0 VS_Fringe();
        PixelShader = compile ps_3_0 PS();
    }
}