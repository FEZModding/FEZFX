// TrixelParticleEffect
// E073D61F2F55F5F1EF95ED05963B56B22572E4CA5C74E9D88594B1535E943DD3

#include "BaseEffect.fxh"   // NOTE: BaseAmbient was float1 type

// Row 1 : Position (xyz), Unused (w)
// Row 2 : Scale (xyz), Unused (w)
// Row 3 : Color with alpha (xyzw)
// Row 4 : Texture matrix { m11, m22, m31, m32 } (xyzw)
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
    float4x4 data = InstanceData[int(input.InstanceIndex)];

    output.Color = data[2];
    output.Normal = input.Normal;
    output.TexCoord = input.TexCoord * data[3].xy + data[3].zw;
    
    float4x4 xform = CreateTransform(data[0].xyz, data[1].xyz);
    float4 position = mul(input.Position, xform);
    position = ApplyEyeParallax(position);

    float4 worldViewPos = TransformPositionToClip(position); 
    output.Position = ApplyTexelOffset(worldViewPos);

    return output;
}

float4 PS_Pre(VS_OUTPUT input) : COLOR0
{
    float3 emissive = saturate(input.Color.rgb - 1.0);
    float3 shade = PerAxisShading(input.Normal, emissive.x);
    
    float4 texColor = SAMPLE_TEXTURE(BaseTexture, input.TexCoord);
    float3 color = DiffuseLight * 0.5 * shade + (1.0 - DiffuseLight) * emissive;
    float alpha = input.Color.a * (1.0 - texColor.a);

    return float4(color, alpha);
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    float4 texColor = SAMPLE_TEXTURE(BaseTexture, input.TexCoord);
    float3 color = texColor.rgb * input.Color.rgb;
    float alpha =  input.Color.a * (1.0 - texColor.a);

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
