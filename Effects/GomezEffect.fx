// GomezEffect
// E7E874FBD447516974FB518CE3131179769605707DF3AA455BF857CEA2EAE606

#include "BaseEffect.fxh"

static const float HAT_OFFSET = 0.3875;  // 0.41875 ?

float NoMoreFez;    // boolean
float Silhouette;   // boolean
float ColorSwap;    // boolean
float Background;

float3 RedSwap;
float3 BlackSwap;
float3 WhiteSwap;
float3 YellowSwap;
float3 GraySwap;

DECLARE_TEXTURE(AnimatedTexture);

struct VS_INPUT
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float Fog : TEXCOORD1;
    float2 TexCoord : TEXCOORD2;
    float HatCoord : TEXCOORD3;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float4 worldPos = TransformPositionToWorld(input.Position);
    worldPos = ApplyEyeParallax(worldPos);

    float4 worldViewPos = TransformWorldToClip(worldPos);
    output.Position = ApplyTexelOffset(worldViewPos);
    output.TexCoord = TransformTexCoord(input.TexCoord);
    
    output.HatCoord = input.TexCoord.y * 2.0 - HAT_OFFSET;
    output.Fog = saturate(ApplyFog(output.Position.w));

    return output;
}

float4 PS_Pre(VS_OUTPUT input) : COLOR0
{
    float4 texColor = SAMPLE_TEXTURE(AnimatedTexture, input.TexCoord);
    float alpha = texColor.a * Material_Opacity;

    ApplyAlphaTest(alpha);

    if (NoMoreFez != 0.0)
    {
        if (texColor.r < 0.5)
        {
            if (input.HatCoord < 0.0) discard;
        }
        else if (texColor.g < 0.25) discard;
        else if (texColor.b < 0.5) discard;
    }

    return float4(DiffuseLight * 0.5, sign(alpha));
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    float4 texColor = SAMPLE_TEXTURE(AnimatedTexture, input.TexCoord);

    float3 color = texColor.rgb;
    float alpha = texColor.a * Material_Opacity;
    
    ApplyAlphaTest(alpha);
    
    if (ColorSwap != 0.0)
    {    
        if (color.r < 0.5)          color = BlackSwap;
        else if (color.g < 0.5)     color = RedSwap;
        else if (color.b < 0.5)     color = YellowSwap;
        else if (color.r > 0.75)    color = WhiteSwap;
        else                        color = GraySwap;
    }
    
    if (NoMoreFez != 0.0)
    {
        if (color.r < 0.5)
        {
            if (input.HatCoord < 0.0) discard;
        }
        else if (color.g < 0.25) discard;
        else if (color.b < 0.5) discard;
    }

    if (Silhouette != 0.0)
    {
        color = 0.0;
        alpha *= 0.5;
    }

    color = lerp(color, color * 0.5, Background);
    color = lerp(color, Fog_Color, 1.0 - input.Fog);

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
