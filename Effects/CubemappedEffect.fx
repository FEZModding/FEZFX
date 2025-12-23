// CubemappedEffect
// AD296A9BA42B7803025C1F7CD6A009F707EA411D49C6E6A5476E178D1F7C6273

#include "BaseEffect.fxh"

float ForceShading;

texture CubemapTexture;
sampler2D CubemapSampler = sampler_state
{
    Texture = <CubemapTexture>;
};

struct VS_INPUT
{
    float4 Position : POSITION0;
    float4 Normal : NORMAL0;
    float2 TexCoord : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float4 Normal : TEXCOORD0;
    float FogFactor : TEXCOORD1;
    float2 TexCoord : TEXCOORD2;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float4 worldViewPos = TransformPositionToClip(input.Position);
    output.Position = ApplyTexelOffset(worldViewPos);
    output.Normal = TransformNormalToWorld(input.Normal);
    
    if (Fog_Type == FOG_TYPE_EXP_SQR)
    {
        output.FogFactor = ApplyExponentialSquaredFog(worldViewPos.w, Fog_Density);
    }
    else if (Fog_Type == FOG_TYPE_NONE)
    {
        output.FogFactor = 1.0;
    }

    output.TexCoord = input.TexCoord;

    return output;
}

float4 PS_Pre(VS_OUTPUT input) : COLOR0
{
    float3 normal = input.Normal.xyz;

    // Calculate ambient contribution
    float4 texColor = tex2D(CubemapSampler, input.TexCoord);
    float3 ambient = saturate(texColor.a + BaseAmbient);
    float3 invAmbient = 1.0 - BaseAmbient;
    float3 alphaAmbient = texColor.a * BaseAmbient;

    // Front lighting
    float normalDotLight = saturate(dot(normal, 1.0));
    float3 frontLighting = normalDotLight * invAmbient + ambient;

    // Back lighting
    float3 backLighting = abs(normal.z) * invAmbient * 0.6 + frontLighting;
    float3 lighting = (normal.z >= -0.01) ? frontLighting : backLighting;

    // Side lighting
    float3 sideLighting = abs(normal.x) * invAmbient * 0.3 + lighting;
    lighting = saturate((normal.x >= -0.01) ? lighting : sideLighting);

    // Apply diffuse and alpha color on material
    float3 color = (lighting * DiffuseLight + alphaAmbient) * 0.5;

    return float4(color, Material_Opacity);
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    float3 normal = input.Normal.xyz;

    // Calculate ambient contribution
    float4 texColor = tex2D(CubemapSampler, input.TexCoord);
    float3 ambient = saturate(texColor.a + BaseAmbient);
    float3 invAmbient = 1.0 - BaseAmbient;
    float3 invDiffuse = 1.0 - DiffuseLight;
    float3 alphaInvDiffuse = texColor.a * invDiffuse;

    // Front lighting
    float normalDotLight = saturate(dot(normal, 1.0));
    float3 frontLighting = normalDotLight * invAmbient + ambient;

    // Back lighting
    float3 backLighting = abs(normal.z) * invAmbient * 0.6 + frontLighting;
    float3 lighting = (normal.z >= -0.01) ? frontLighting : backLighting;

    // Side lighting
    float3 sideLighting = abs(normal.x) * invAmbient * 0.3 + lighting;
    lighting = saturate((normal.x >= -0.01) ? lighting : sideLighting);

    // Apply diffuse and material color
    float3 unshadedColor = texColor.rgb * Material_Diffuse;
    float3 litColor = lighting * DiffuseLight + alphaInvDiffuse;
    float3 shadedColor = unshadedColor * litColor;

    // Choose between shaded and unshaded color
    float3 color = (ForceShading) ? shadedColor : unshadedColor;
    color = lerp(color, Fog_Color, input.FogFactor);

    return float4(color, Material_Opacity);
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
