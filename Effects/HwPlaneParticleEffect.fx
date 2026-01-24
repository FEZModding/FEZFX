// HwPlaneParticleEffect
// CC2E9D0C9242C774781649C5E33D80860918C8385A3DDC5AB4661C18E040BDBE

#include "BaseEffect.fxh"

float Fullbright;       // boolean
float Additive;         // boolean

DECLARE_TEXTURE(BaseTexture);

struct VS_INPUT
{
    float4 Position : POSITION;
    float2 TexCoord : TEXCOORD0;
    float4 Data0 : TEXCOORD2;     // Row 1 : Position (xyz), Phi (w)
    float4 Data1 : TEXCOORD3;       // Row 2 : Scale (xyz), Unused (w)
    float4 Data2 : TEXCOORD4;      // Row 3 : Color with alpha (xyzw)
};

struct VS_OUTPUT
{
    float2 TexCoord : TEXCOORD0;
    float4 Color : TEXCOORD1;
    float4 Position : POSITION;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float3x3 basis = PhiToMatrix(input.Data0.w);
    float4x4 xform = CreateTransform(input.Data0.xyz, basis, input.Data1.xyz);
    float4 worldPos = mul(input.Position, xform);
    worldPos = ApplyEyeParallax(worldPos);

    float4 worldViewPos = TransformPositionToClip(worldPos);
    output.Position = ApplyTexelOffset(worldViewPos);
    output.TexCoord = input.TexCoord;
    output.Color = input.Data2;

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
        VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS_Pre();
    }
    
    pass Main
    {
        VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS_Main();
    }
}
