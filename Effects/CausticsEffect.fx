// CausticsEffect
// E9DB19AD123B12157D5543BC803E3A83A19371EC45655285AF1B06E8B266DC86

#include "Common.fxh"

float3 DiffuseLight;
float3 Material_Diffuse;
float4x4 Matrices_WorldViewProjection;
float3x3 NextFrameData;
float3x3 Matrices_Texture;
float2 TexelOffset;
texture AnimatedTexture;

sampler2D AnimatedSampler = sampler_state
{
    Texture = <AnimatedTexture>;
};

struct VS_INPUT
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
    float FallOff : TEXCOORD1;
    float2 TexCoord2 : TEXCOORD2;
    float BlendAmount : TEXCOORD3;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;
    
    float4 worldPos = mul(input.Position, Matrices_WorldViewProjection);
    output.Position.xy = (TexelOffset * worldPos.w) + worldPos.xy;
    output.Position.zw = worldPos.zw;
    
    float3 texCoord = float3(input.TexCoord, 1.0);
    output.TexCoord = mul(texCoord, Matrices_Texture).xy;
    output.TexCoord2 = mul(texCoord, NextFrameData).xy;
    output.FallOff = 1.0 - input.Position.y;
    output.BlendAmount = NextFrameData[2].z;
    
    return output;
}

float4 PS_Pre(VS_OUTPUT input) : COLOR0
{
    float4 currentFrame = tex2D(AnimatedSampler, input.TexCoord);
    float4 nextFrame = tex2D(AnimatedSampler, input.TexCoord2);
    
    // Blend between animation frames for smooth transitions
    float4 causticColor = lerp(currentFrame, nextFrame, input.BlendAmount);
    
    // Calculate squared falloff for smoother depth attenuation
    float falloffSquared = input.FallOff * input.FallOff;
    causticColor.a *= falloffSquared;
    
    // Apply material color to caustic pattern
    // Note: BGR swizzle maintains color channel relationships
    float3 materialColor = causticColor.bgr * Material_Diffuse.bgr;
    float3 attenuatedColor = falloffSquared * materialColor.zyx;
    
    // Apply caustic intensity and add diffuse light
    const float CAUSTIC_INTENSITY = 0.4;
    float3 color = (attenuatedColor * CAUSTIC_INTENSITY) + DiffuseLight * 0.5;
    float alpha = causticColor.a * CAUSTIC_INTENSITY;
    clip(alpha - ALPHA_THRESHOLD);
    
    return float4(color, alpha);
}

technique TSM2
{
    pass Pre
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS_Pre();
    }
}