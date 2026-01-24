// PlaneParticleEffect
// 7DC84D4ABFEEEFF37A79FB1C4AD9DD6BDC187243DF68E3EFF0BA6207B95FBDB5

#include "BaseEffect.fxh"

// Row 1 : Position (xyz), Phi (w)
// Row 2 : Scale (xyz), Unused (w)
// Row 3 : Color with alpha (xyzw)
// Row 4 : Unused
float4x4 InstanceData[60];

float Fullbright;       // boolean
float Additive;         // boolean

DECLARE_TEXTURE(BaseTexture);

struct VS_INPUT
{
    float4 Position : POSITION;
    float2 TexCoord : TEXCOORD0;
    float InstanceIndex : TEXCOORD1;
};

struct VS_OUTPUT
{
    float4 Position : POSITION;
    float2 TexCoord : TEXCOORD0;
    float4 Color : TEXCOORD1;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;
    float4x4 data = InstanceData[(int)input.InstanceIndex];

    float3x3 basis = PhiToMatrix(data[0].w);
    float4x4 xform = CreateTransform(data[0].xyz, basis, data[1].xyz);
    float4 worldPos = mul(input.Position, xform);
    worldPos = ApplyEyeParallax(worldPos);

    float4 worldViewPos = TransformPositionToClip(worldPos);
    output.Position = ApplyTexelOffset(worldViewPos);
    output.TexCoord = input.TexCoord;
    output.Color = data[2];

    return output;
}

float4 PS_Pre(VS_OUTPUT input) : COLOR0
{
    float4 texColor = SAMPLE_TEXTURE(BaseTexture, input.TexCoord);

    float alpha = (Additive != 0.0)
        ? dot(input.Color.rgb * texColor.rgb, 1.0 / 3.0)
        : input.Color.a * texColor.a;

    float3 color = DiffuseLight + Fullbright * (1.0 - DiffuseLight);

    return float4(color * 0.5, alpha);
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    float4 color = input.Color * SAMPLE_TEXTURE(BaseTexture, input.TexCoord);
    ApplyAlphaTest(color.a);
    return color;
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
