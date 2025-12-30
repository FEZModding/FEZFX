// TrixelParticleEffect
// E073D61F2F55F5F1EF95ED05963B56B22572E4CA5C74E9D88594B1535E943DD3

#include "BaseEffect.fxh"   // NOTE: BaseAmbient was float1 type

float4x4 InstanceData[60];

DECLARE_TEXTURE(BaseTexture);

struct VS_INPUT
{
    float4 Position : POSITION0;
    float3 Normal : NORMAL0;
    float2 TexCoord : TEXCOORD0;
    float InstanceIndex : TEXCOORD1;
};

struct VS_OUTPUT
{
    float2 TexCoord : TEXCOORD0;
    float4 Color : TEXCOORD1;
    float3 Normal : TEXCOORD2;
    float4 Position : POSITION0;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    int index = trunc(input.InstanceIndex);
    float3 Center = InstanceData[index][0].xyz;
    float3 Size = InstanceData[index][1].xyz;
    float4 Color = InstanceData[index][2];
    float4 TextureMatrix = InstanceData[index][3];

    output.TexCoord = input.TexCoord * TextureMatrix.xy + TextureMatrix.zw;
    
    float4x4 xform = CreateTransform(Center, Size);
    float4 position = mul(input.Position, xform);
    position = ApplyEyeParallax(position);

    float4 worldViewPos = TransformPositionToClip(position); 
    output.Position = ApplyTexelOffset(worldViewPos);

    output.Color = Color;
    output.Normal = input.Normal;

    return output;
}

float4 PS_Pre(VS_OUTPUT input) : COLOR0
{
    float tint = saturate(input.Color.rgb - 1.0);
    float3 color = CalculateLighting(input.Normal, tint.x);

    float4 texColor = SAMPLE_TEXTURE(BaseTexture, input.TexCoord);
    float alpha = (1.0 - texColor.a) * input.Color.a;

    return float4(color * 0.5, alpha);
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    float4 texColor = SAMPLE_TEXTURE(BaseTexture, input.TexCoord);

    float3 color = texColor.rgb * input.Color.rgb;
    float alpha = (1.0 - texColor.a) * input.Color.a;

    return float4(color, alpha);
}

technique TSM2
{
    pass Pre
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS_Pre();
    }

    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS_Main();
    }
}
