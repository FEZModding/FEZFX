// InstancedArtObjectEffect
// F83086F4868F72E7C5F94C135921BE80C1209885934393B253BDD15E14EE6D06

#include "BaseEffect.fxh"

// Row 1 : Position (xyz), Opacity (w)
// Row 2 : Scale (xyz), ForceShading (w)
// Row 3 : Rotation quaternion (xyzw)
// Row 4 : Hidden sides (frbl => xyzw)
float4x4 InstanceData[60];

DECLARE_TEXTURE(CubemapTexture);

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
    float Fog : TEXCOORD1;
    float2 TexCoord : TEXCOORD2;
    float ClipValue : TEXCOORD3;
    float Opacity : TEXCOORD4;
    float ForceShading : TEXCOORD5;
    float4 Position : POSITION0;
};

float ComputeVisibility(float3 normal, float4 hideSides)
{
    if (hideSides[0] != 0.0 && normal.z > 0.5) return -1.0;    // front
    if (hideSides[1] != 0.0 && normal.x > 0.5) return -1.0;    // right
    if (hideSides[2] != 0.0 && normal.z < -0.5) return -1.0;   // back
    if (hideSides[3] != 0.0 && normal.x < -0.5) return -1.0;   // left
    return 1.0;
}

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;
    float4x4 data = InstanceData[(int)input.InstanceIndex];

    float3x3 basis = QuaternionToMatrix(data[2]);
    float4x4 xform = CreateTransform(data[0].xyz, basis, data[1].xyz);
    
    float4 worldPos = mul(input.Position, xform);
    worldPos = ApplyEyeParallax(worldPos);
    float4 worldViewPos = TransformPositionToClip(worldPos);
    output.Position = ApplyTexelOffset(worldViewPos);

    output.Fog = 1.0 - ApplyFog(output.Position.w);
    output.Normal = mul(input.Normal, basis);
    output.ClipValue = ComputeVisibility(output.Normal, data[3]);
    
    output.TexCoord = input.TexCoord;
    output.ForceShading = data[1].w > 0.5 ? 1.0 : 0.0;
    output.Opacity = data[0].w;

    return output;
}

float4 PS_Pre(VS_OUTPUT input) : COLOR0
{
    clip(input.ClipValue);
    ApplyAlphaTest(input.Opacity);

    float4 texColor = SAMPLE_TEXTURE(CubemapTexture, input.TexCoord);
    
    float3 light = ComputeLight(input.Normal, texColor.a);
    float3 color = lerp(light, 1.0, input.Fog);

    return float4(color * 0.5, input.Opacity);
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    clip(input.ClipValue);
    ApplyAlphaTest(input.Opacity);

    float4 texColor = SAMPLE_TEXTURE(CubemapTexture, input.TexCoord);

    float3 light = texColor.rgb;
    if (input.ForceShading > 0.5)
    {
        light *= ComputeLight(input.Normal, texColor.a);
    }

    float3 color = lerp(light, Fog_Color, input.Fog);

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
