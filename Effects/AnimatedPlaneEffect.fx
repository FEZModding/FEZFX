// AnimatedPlaneEffect
// D20469736E1BE3F4BB4D2507D630EEC770507C4F7C5BEB0D60DE1BB9CFFC6A01

#include "BaseEffect.fxh"

float Fullbright;       // boolean
float AlphaIsEmissive;  // boolean
float IgnoreShading;    // boolean
float IgnoreFog;        // boolean
float SewerHax;         // boolean

DECLARE_TEXTURE(AnimatedTexture);

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
    float4 texColor = SAMPLE_TEXTURE(AnimatedTexture, input.TexCoord);
    
    float alpha = texColor.a * Material_Opacity;
    if (AlphaIsEmissive)
    {
        ApplyAlphaTest(alpha);
    }

    float brightness = texColor.a;
    if (!AlphaIsEmissive)
    {
        brightness = Fullbright;
    }
    if (IgnoreShading)
    {
        brightness = 1.0;
    }
    float3 litColor = CalculateLighting(input.Normal, brightness);

    float3 color = lerp(litColor, 1.0, input.FogFactor);
    if (SewerHax)
    {
        color = (texColor.r < 0.75) ? 0.0 : 1.0;
    }
    color *= 0.5;

    if (AlphaIsEmissive)
    {
        alpha = Material_Opacity;
    }

    return float4(color, alpha);
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    float4 texColor = SAMPLE_TEXTURE(AnimatedTexture, input.TexCoord);
    float alpha = texColor.a * Material_Opacity;
    if (AlphaIsEmissive)
    {
        ApplyAlphaTest(alpha);
    }

    float3 color = texColor.rgb * Material_Diffuse;
    color = lerp(color, Fog_Color, input.FogFactor);
    
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
