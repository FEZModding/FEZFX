// CausticsEffect
// E9DB19AD123B12157D5543BC803E3A83A19371EC45655285AF1B06E8B266DC86

#include "BaseEffect.fxh"

static const float CAUSTIC_INTENSITY = 0.4;

float3x3 NextFrameData;

DECLARE_TEXTURE(AnimatedTexture);

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

    float4 worldViewPos = TransformPositionToClip(input.Position);
    output.Position = ApplyTexelOffset(worldViewPos);

    output.TexCoord = TransformTexCoord(input.TexCoord);
    output.TexCoord2 = TransformTexCoord(input.TexCoord, NextFrameData);

    output.FallOff = 1.0 - input.Position.y;
    output.BlendAmount = NextFrameData[2].z;

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    float4 currentFrame = SAMPLE_TEXTURE(AnimatedTexture, input.TexCoord);
    float4 nextFrame = SAMPLE_TEXTURE(AnimatedTexture, input.TexCoord2);

    float4 causticColor = lerp(currentFrame, nextFrame, input.BlendAmount);
    float falloff = pow(input.FallOff, 2);
    
    float3 color = falloff * causticColor.rgb * Material_Diffuse * CAUSTIC_INTENSITY;
    color += DiffuseLight * 0.5;
    
    float alpha = causticColor.a * falloff * CAUSTIC_INTENSITY;
    ApplyAlphaTest(alpha);
    
    return float4(color, alpha);
}

technique TSM2
{
    pass Pre
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}