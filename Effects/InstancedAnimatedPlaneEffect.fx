// InstancedAnimatedPlaneEffect
// F02CFF9DEBF7418D09E7EC5BA6E9B2EB3E2D1D6C541B959857C10A14BBA80748

#include "BaseEffect.fxh"

// Row 1 : Position (xyz), TU Frame Offset (w)
// Row 2 : Quaternion (xyzw)
// Row 3 : Scale (xz), TV Frame Offset (z),  (w bit 1), ClampTexture (w bit 2), XTextureRepeat (w bit 3), YTextureRepeat (w bit 4)
// Row 4 : Diffuse (xyz), Opacity (w)
float4x4 InstanceData[58];

float IgnoreFog;        // boolean
float SewerHax;         // boolean
float IgnoreShading;    // boolean
float2 FrameScale;

DECLARE_TEXTURE(AnimatedTexture);

struct VS_INPUT
{
    float4 Position : POSITION0;
    float3 Normal : NORMAL0;
    float2 TexCoord : TEXCOORD0;
    float InstanceIndex : TEXCOORD1;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
    float3 Normal : TEXCOORD1;
    float Fog : TEXCOORD2;
    float4 Material : TEXCOORD3;
    float2 FullbrightRepeat : TEXCOORD4;
    float2 VMinMax : TEXCOORD5;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;
    float4x4 data = InstanceData[(int)input.InstanceIndex];

    float flags = data[2].w;
    bool fullbright = fmod(flags, 2.0) == 1.0;
    bool clampTexture = fmod(flags, 4.0) >= 2.0;
    bool xTextureRepeat = fmod(flags, 8.0) >= 4.0;
    bool yTextureRepeat = fmod(flags, 16.0) >= 8.0;

    float3x3 xform2D = float3x3(
        clampTexture || xTextureRepeat ? data[2].x : 1.0, 0.0, 0.0,
        0.0, clampTexture || yTextureRepeat ? data[2].y : 1.0, 0.0,
        0.0, 0.0, 1.0
    );
    float2 texCoord = TransformTexCoord(input.TexCoord, xform2D);
    output.TexCoord = texCoord * FrameScale + float2(data[0].w, data[2].z);     // atlas/animation

    float3x3 basis = QuaternionToMatrix(data[1]);
    float4x4 xform = CreateTransform(data[0].xyz, basis, float3(data[2].xy, 1.0));
    float4 worldPos = mul(input.Position, xform);
    worldPos = ApplyEyeParallax(worldPos);
    float4 worldViewPos = TransformPositionToClip(worldPos);
    output.Position = ApplyTexelOffset(worldViewPos);

    output.Normal = normalize(mul(input.Normal, basis));
    output.Fog = (IgnoreFog != 0.0)
        ? 0.0
        : saturate(1.0 - ApplyFog(output.Position.w));
    
    output.FullbrightRepeat = float2((fullbright ? 1.0 : 0.0), (yTextureRepeat ? 1.0 : 0.0));
    output.Material = data[3];
    output.VMinMax = float2(data[2].z, FrameScale.y);

    return output;
}

float4 PS_Pre(VS_OUTPUT input) : COLOR0
{
    float2 texCoord = input.TexCoord;
    if (input.FullbrightRepeat.y == 1.0)
    {
        float wrappedV = frac((texCoord.y - input.VMinMax[0]) / input.VMinMax[1]);
        texCoord.y = wrappedV * input.VMinMax[1] + input.VMinMax[0];
    }
    
    float4 texColor = SAMPLE_TEXTURE(AnimatedTexture, texCoord);
    float alpha = input.Material.a * texColor.a;
    ApplyAlphaTest(alpha);

    float emissive = (IgnoreShading != 0.0) ? 1.0 : input.FullbrightRepeat.x;
    float3 light = ComputeLight(input.Normal, emissive);
    
    float3 color = lerp(light, 1.0, input.Fog);
    if (SewerHax != 0.0)
    {
        color = texColor.r > 0.75 ? 1.0 : 0.0;
    }

    return float4(color * 0.5, alpha);
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    float2 texCoord = input.TexCoord;
    float wrappedV = frac((texCoord.y - input.VMinMax[0]) / input.VMinMax[1]);
    texCoord.y = wrappedV * input.VMinMax[1] + input.VMinMax[0];
    
    float4 texColor = SAMPLE_TEXTURE(AnimatedTexture, texCoord);
    float alpha = texColor.a * input.Material.a;
    ApplyAlphaTest(alpha);

    float3 color = texColor.rgb * input.Material.rgb;
    color = lerp(color, Fog_Color, input.Fog);

    return float4(color, alpha);
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
