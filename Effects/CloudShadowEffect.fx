// CloudShadowEffect
// 5AF26C88082387477D4B10A9D4F5FA041EDB38B04C365204CA62C4468258F8B4

#include "BaseEffect.fxh"

DECLARE_TEXTURE(BaseTexture);

struct VS_INPUT
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
    float3 Normal : NORMAL0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
    float3 Normal : TEXCOORD1;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;
    
    float4 worldViewPos = TransformPositionToClip(input.Position);
    output.Position = ApplyTexelOffset(worldViewPos);
    output.TexCoord = TransformTexCoord(input.TexCoord);
    output.Normal = input.Normal;
    
    return output;
}

float4 PS_Standard(VS_OUTPUT input) : COLOR0
{
    float4 texColor = SAMPLE_TEXTURE(BaseTexture, input.TexCoord);
    float3 color = 1.0 - (texColor.rrr * Material_Opacity);
    
    return float4(color, 1.0);
}

float4 PS_Canopy(VS_OUTPUT input) : COLOR0
{
    float4 texColor = SAMPLE_TEXTURE(BaseTexture, input.TexCoord);
    
    float3 invAmbient = 1.0 - BaseAmbient;
    float3 ambient = saturate(BaseAmbient);
    float ndotl = saturate(dot(input.Normal, 1.0));
    float3 lighting = ndotl * invAmbient + ambient;
    
    // Back lighting for surfaces facing away
    if (input.Normal.z < -0.01)
        lighting = abs(input.Normal.z) * invAmbient * 0.6 + lighting;
    
    // Side lighting for surfaces facing left
    if (input.Normal.x < -0.01)
        lighting = abs(input.Normal.x) * invAmbient * 0.3 + lighting;
    
    float3 canopyColor = lerp(saturate(lighting), 1.0, 0.75);
    float3 lightingDelta = canopyColor * (DiffuseLight * 0.5) - (BaseAmbient * 0.5);
    
    float shadowAttenuation = 1.0 - texColor.r * Material_Opacity;
    float3 color = lightingDelta * shadowAttenuation + (BaseAmbient * 0.5);
    
    return float4(color, 1.0);
}

technique TSM2
{
    pass Standard
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS_Standard();
    }

    pass Canopy
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS_Canopy();
    }
}