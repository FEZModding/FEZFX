// InstancedArtObjectEffect
// F83086F4868F72E7C5F94C135921BE80C1209885934393B253BDD15E14EE6D06

#include "BaseEffect.fxh"

float4x4 InstanceData[60];

texture CubemapTexture;
sampler2D CubemapSampler = sampler_state
{
    Texture = <CubemapTexture>;
};

struct VS_INPUT
{
    float4 Position : POSITION0;
    float3 Normal : NORMAL0;
    float2 TexCoord : TEXCOORD0;
    float InstanceIndex: TEXCOORD1;
};

struct VS_OUTPUT
{
    float3 Normal : TEXCOORD0;
    float FogFactor : TEXCOORD1;
    float2 TexCoord : TEXCOORD2;
    float Visibility : TEXCOORD3;
    float Opacity : TEXCOORD4;
    float ForceShading : TEXCOORD5;
    float4 Position : POSITION0;
};

float ComputeVisibility(float3 normal, float4 invisibleSides)
{
    // Facing front (+Z) and front is invisible
    if (normal.z > 0.5 && invisibleSides.x)
    {
        return -1.0;
    }

    // Facing right (+X) and right is invisible
    if (normal.x > 0.5 && invisibleSides.y)
    {
        return -1.0;
    }

    // Facing back (-Z) and back is invisible
    if (normal.z < -0.5 && invisibleSides.z)
    {
        return -1.0;
    }

    // Facing left (-X) and left is invisible
    if (normal.x < -0.5 && invisibleSides.w)
    {
        return -1.0;
    }

    return 1.0;
}

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    int index = trunc(input.InstanceIndex);
    float3 Position = InstanceData[index][0].xyz;
    float Opacity = InstanceData[index][0].w;
    float3 Scale = InstanceData[index][1].xyz;
    float ForceShading = InstanceData[index][1].w;
    float4 Rotation = InstanceData[index][2];
    float4 InvisibleSides = InstanceData[index][3];

    float3x3 basis = QuaternionToMatrix(Rotation);
    float4x4 xform = CreateTransform(Position, basis, Scale);
    
    float4 worldPos = mul(input.Position, xform);
    worldPos = ApplyEyeParallax(worldPos);
    float4 worldViewPos = TransformPositionToClip(worldPos);
    output.Position = ApplyTexelOffset(worldViewPos);

    output.FogFactor = ApplyFog(worldViewPos.w, Fog_Density);
    output.Normal = mul(input.Normal, basis);
    output.Visibility = ComputeVisibility(output.Normal, InvisibleSides);
    
    output.TexCoord = input.TexCoord;
    output.Opacity = Opacity;
    output.ForceShading = ForceShading;

    return output;
}

float4 PS_Pre(VS_OUTPUT input) : COLOR0
{
    clip(input.Visibility);
    ApplyAlphaTest(input.Opacity);

    float4 texColor = tex2D(CubemapSampler, input.TexCoord);
    
    float3 color = CalculateLighting(input.Normal, texColor.a);
    color = lerp(color, 1.0, input.FogFactor);

    return float4(color * 0.5, input.Opacity);
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    clip(input.Visibility);
    ApplyAlphaTest(input.Opacity);

    float4 texColor = tex2D(CubemapSampler, input.TexCoord);

    float3 color = texColor.rgb;
    if (input.ForceShading)
    {
        color *= CalculateLighting(input.Normal, texColor.a);
    }

    color = lerp(color, Fog_Color, input.FogFactor);

    return float4(color, input.Opacity);
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
