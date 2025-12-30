// HwTrixelParticleEffect
// 4A4BD6EB0E30FE770E35FE9BD0EE69B4DFC0CA8BFDD76EFA0A96548A30BD8C3E

#include "BaseEffect.fxh"   // NOTE: BaseAmbient was float1 type

DECLARE_TEXTURE(BaseTexture);

struct VS_INPUT
{
    float4 Position : POSITION0;
    float3 Normal : NORMAL0;
    float2 TexCoord : TEXCOORD0;
    float3 Center : TEXCOORD2;
    float3 Size : TEXCOORD3;
    float4 Color : TEXCOORD4;
    float4 TextureMatrix : TEXCOORD5;
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

    output.TexCoord = input.TexCoord * input.TextureMatrix.xy + input.TextureMatrix.zw;
    
    float4x4 xform = CreateTransform(input.Center, input.Size);
    float4 position = mul(input.Position, xform);
    position = ApplyEyeParallax(position);

    float4 worldViewPos = TransformPositionToClip(position); 
    output.Position = ApplyTexelOffset(worldViewPos);

    output.Color = input.Color;
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
        VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS_Pre();
    }

    pass Main
    {
        VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS_Main();
    }
}
