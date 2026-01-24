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
    float3 shadow = texColor.rrr * Material_Opacity;
    return float4(1.0 - shadow, 1.0);
}

float4 PS_Canopy(VS_OUTPUT input) : COLOR0
{
    float3 mult2xAmbient = BaseAmbient / 2.0;
    float3 mult2xDirect = DiffuseLight / 2.0;

    // FIXME: Hacked from -Eye because of preshader/saturate bug
    float3 shading = PerAxisShading(input.Normal, 0.0);
    // This fails sometimes because eye normal != world normal
    float3 faceShading = lerp(shading, 1.0, 0.75) * mult2xDirect;

    float4 texColor = SAMPLE_TEXTURE(BaseTexture, input.TexCoord);
    float shadow = texColor.r * Material_Opacity;
    float3 color = mult2xAmbient + (faceShading - mult2xAmbient) * (1.0 - shadow);

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