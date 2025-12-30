// StaticPlaneEffect
// 0169CD775004E50AE43B2C740F06597A2D2B10CEE1405B4516E823A807704655

#include "BaseEffect.fxh"

float Fullbright;       // boolean
float AlphaIsEmissive;  // boolean
float IgnoreFog;        // boolean
float SewerHax;         // boolean

DECLARE_TEXTURE(BaseTexture);

struct VS_INPUT
{
    float4 Position : POSITION0;
    float3 Normal : NORMAL0;
    float2 TexCoord : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
    float3 Normal : TEXCOORD1;
    float FogFactor : TEXCOORD2;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float4 worldPos = TransformPositionToWorld(input.Position);
    worldPos = ApplyEyeParallax(worldPos);
    float4 worldViewPos = TransformWorldToClip(worldPos);
    output.Position = ApplyTexelOffset(worldViewPos);

    output.TexCoord = TransformTexCoord(input.TexCoord);
    output.Normal = TransformNormalToWorld(input.Normal);
    output.FogFactor = (IgnoreFog) ? 0.0 : saturate(ApplyFog(worldViewPos.w, Fog_Density));

    return output;
}

float4 PS_Pre(VS_OUTPUT input) : COLOR0
{
    float4 texColor = SAMPLE_TEXTURE(BaseTexture, input.TexCoord);

    float brightness = 0.0;
    if (Fullbright)
    {
        brightness = texColor.a * Material_Opacity;
    }
    if (AlphaIsEmissive)
    {
        brightness = texColor.a;
    }

    float3 litColor = CalculateLighting(input.Normal, brightness);

    float3 color = lerp(litColor, 1.0, input.FogFactor);
    if (SewerHax)
    {
        color = (texColor.r < 0.75) ? 0.0 : 1.0;
    }
    color *= 0.5;

    return float4(color, 1.0);
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    float4 texColor = SAMPLE_TEXTURE(BaseTexture, input.TexCoord);

    float3 color = texColor.rgb * Material_Diffuse;
    color = lerp(color, Fog_Color, input.FogFactor);

    float alpha = texColor.a * Material_Opacity;
    if (AlphaIsEmissive)
    {
        alpha = Material_Opacity;
    }

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
