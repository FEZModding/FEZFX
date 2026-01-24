#ifndef DEFAULT_EFFECT_FXH
#define DEFAULT_EFFECT_FXH

#include "BaseEffect.fxh"

static const float3 DEFAULT = 0.5;
static const float3 LUMINANCE = 1.0 / 3.0;

float AlphaIsEmissive;  // boolean
float Fullbright;       // boolean
float Emissive;

float TextureEnabled;   // boolean
float SpecularEnabled;  // boolean

DECLARE_TEXTURE(BaseTexture);

float3 ComputeLightWithSpecular(float3 normal, float emissive, float3 color)
{
    color *= ComputeLight(normal, emissive);
    if (SpecularEnabled != 0.0)
    {
        float3 eyeDir = Eye - float3(0.0, 0.25, 0.0);
        float specular = dot(eyeDir, normal);
        color += saturate(pow(specular, 8)) * 0.5;
    }

    return color;
}

float4 CalculatePrePassTextured(float4 texColor)
{
    float emissive = Emissive;
    if (Fullbright != 0.0)
    {
        emissive = 1.0;
    }
    else if (TextureEnabled != 0.0)
    {
        if (AlphaIsEmissive != 0.0)
        {
            emissive = texColor.a;
        }
        else
        {
            emissive = dot(texColor.rgb, LUMINANCE);
        }
    }

    if (AlphaIsEmissive != 0.0)
    {
        return float4(emissive * Material_Diffuse * 0.5, 1.0);
    }
    else
    {
        return float4(DEFAULT, emissive * Material_Opacity);
    }
}

float4 CalculatePrePassVertexColored()
{
    float emissive = (Fullbright != 0.0) ? 1.0 : Emissive;
    if (AlphaIsEmissive != 0.0)
    {
        return float4(emissive * Material_Diffuse * 0.5, 1.0);
    }
    else
    {
        return float4(DEFAULT, emissive * Material_Opacity);
    }
}

#endif // DEFAULT_EFFECT_FXH