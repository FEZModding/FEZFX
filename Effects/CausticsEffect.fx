// CausticsEffect
// E9DB19AD123B12157D5543BC803E3A83A19371EC45655285AF1B06E8B266DC86

#include "BaseEffect.fxh"

static const float BASE_OPACITY = 0.4;

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
    float Opacity : TEXCOORD1;
    float2 NextFrameTexCoord : TEXCOORD2;
    float NextFrameContrib : TEXCOORD3;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float4 worldViewPos = TransformPositionToClip(input.Position);
    output.Position = ApplyTexelOffset(worldViewPos);
    output.TexCoord = TransformTexCoord(input.TexCoord);
    output.Opacity = 1.0 - input.Position.y;

    float3x3 nextFrameData = NextFrameData;
    output.NextFrameContrib = nextFrameData[2][2];
    nextFrameData[2][2] = 1.0;
    output.NextFrameTexCoord = TransformTexCoord(input.TexCoord, nextFrameData);

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    float4 currentFrame = SAMPLE_TEXTURE(AnimatedTexture, input.TexCoord);
    float4 nextFrame = SAMPLE_TEXTURE(AnimatedTexture, input.NextFrameTexCoord);
    float4 texColor = lerp(currentFrame, nextFrame, input.NextFrameContrib);

    float opacity = pow(input.Opacity, 2.0);
    float alpha = texColor.a * opacity * BASE_OPACITY;
    ApplyAlphaTest(alpha);
    
    float3 color = texColor.rgb * Material_Diffuse * opacity * 0.4;
    color += 0.5 * DiffuseLight;
    
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