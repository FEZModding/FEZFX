// HwInstancedArtObjectEffect
// FA04DD1AF77BA1D4DD5C3B35FD9397A2B47679DDA79EFBE13AC62B04B73588BA

#include "BaseEffect.fxh"

DECLARE_TEXTURE(CubemapTexture);

struct VS_INPUT
{
    float4 Position : POSITION0;
    float3 Normal : NORMAL0;
    float2 TexCoord : TEXCOORD0;
    float4 InstanceData0 : TEXCOORD2;    // Position, Opacity
    float4 InstanceData1 : TEXCOORD3;    // Scale, ForceShading
    float4 InstanceData2 : TEXCOORD4;    // Rotation
    float4 InstanceData3 : TEXCOORD5;    // InvisibleSides: Front, Right, Back, Left
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

    float3 Position = input.InstanceData0.xyz;
    float Opacity = input.InstanceData0.w;
    float3 Scale = input.InstanceData1.xyz;
    float ForceShading = input.InstanceData1.w;
    float4 Rotation = input.InstanceData2;
    float4 InvisibleSides = input.InstanceData3;

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

    float4 texColor = SAMPLE_TEXTURE(CubemapTexture, input.TexCoord);
    
    float3 color = CalculateLighting(input.Normal, texColor.a);
    color = lerp(color, 1.0, input.FogFactor);

    return float4(color * 0.5, input.Opacity);
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    clip(input.Visibility);
    ApplyAlphaTest(input.Opacity);

    float4 texColor = SAMPLE_TEXTURE(CubemapTexture, input.TexCoord);

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
        VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS_Pre();
    }

    pass Main
    {
        VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS_Main();
    }
}
