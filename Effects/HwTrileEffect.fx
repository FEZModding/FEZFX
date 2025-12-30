// HwTrileEffect
// A0639906EE6453880556104A62FADC26CF5CB27FA7A718AA775AB106FABD4D71

#include "BaseEffect.fxh"

static const float4 EMPLACEMENT_CENTER = float4(0.5, 0.5, 0.5, 0.0);
static const float TIME_FREQUENCY = -2.5 / TAU;
static const float INDEX_FREQUENCY = 27.5 / TAU;

float Blink;            // boolean
float Unstable;         // boolean
float TiltTwoAxis;      // boolean
float Shiny;            // boolean
float ForceShading;     // boolean, unused

DECLARE_TEXTURE(AtlasTexture);

struct VS_INPUT
{
    float4 Position : POSITION0;
    float3 Normal : NORMAL0;
    float2 TexCoord : TEXCOORD0;
    float4 InstancePositionPhi : TEXCOORD2;     // Position, Phi
    float InstanceIndex : TEXCOORD3;            // Index
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float3 Normal : TEXCOORD0;
    float FogFactor : TEXCOORD1;
    float2 TexCoord : TEXCOORD2;
    float2 Shininess : TEXCOORD3;   // Brightness offset, Highlight intensity
    float Visibility : TEXCOORD4;   // Blink visibility (0 or 1)
};

float3x3 ApplyUnstable(float index, float4 position, float3x3 basis, out float specular)
{
    specular = 0.0;
    if (Unstable)
    {
        float time = index * INDEX_FREQUENCY + Time;
        float rotating = frac(time * TIME_FREQUENCY) < 0.125 ? 1 : 0;

        float angle = frac(0.5 + time * TIME_FREQUENCY * 2);
        float s, c;
        sincos(angle, s, c);

        float weight = saturate(dot(position.xyz, 1.0) * 0.5);
        specular = max(s, 0) * weight;

        if (rotating)
        {
            float3x3 unstable = float3x3(
                c * c,      s,      -s * c,
                -s * c,     c,      s * s,
                s,          0,      c
            );
            
            return mul(basis, unstable);
        }
    }

    return basis;
}

float3x3 ApplyTiltTwoAxis(float3x3 basis)
{
    if (TiltTwoAxis)
    {
        float3x3 tilt = float3x3(
            sqrt(2.0) / 2.0,    1.0 / sqrt(3.0),    sqrt(2.0) / 2.0,
            0.0,                1.0 / sqrt(3.0),    -sqrt(2.0 / 3.0),
            -sqrt(2.0) / 2.0,   1.0 / sqrt(3.0),    sqrt(2.0) / 2.0
        );

        return mul(tilt, basis);
    }

    return basis;
}

float IsBlinking(float index)
{
    if (Blink)
    {
        float time = index * INDEX_FREQUENCY + Time * 0.1;
        return frac(time) < 0.75 ? 1 : 0;
    }
    
    return 1;
}

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float3 Position = input.InstancePositionPhi.xyz;
    float Phi = input.InstancePositionPhi.w;
    float Index = input.InstanceIndex;
    
    float specular;
    float3x3 basis = PhiToMatrix(Phi);
    basis = ApplyUnstable(Index, input.Position, basis, specular);
    basis = ApplyTiltTwoAxis(basis);

    float4x4 xform = CreateTransform(Position + EMPLACEMENT_CENTER, basis);
    float4 worldPos = mul(input.Position, xform);
    worldPos = ApplyEyeParallax(worldPos);
    
    float4 worldViewPos = TransformPositionToClip(worldPos);
    output.Position = ApplyTexelOffset(worldViewPos);
    output.Normal = mul(input.Normal, basis);

    output.FogFactor = ApplyFog(worldViewPos.w, Fog_Density);
    output.TexCoord = input.TexCoord;

    output.Shininess = 0;
    if (Shiny)
    {
        output.Shininess = float2(0.35, 0.85);
    }
    else if (Unstable)
    {
        output.Shininess = float2(0.4, specular);
    }

    output.Visibility = IsBlinking(Index);

    return output;
}

float4 PS_Pre(VS_OUTPUT input) : COLOR0
{
    float4 texColor = SAMPLE_TEXTURE(AtlasTexture, input.TexCoord);

    float brightness = (texColor.a + input.Shininess.x) * input.Visibility;
    float3 litColor = CalculateLighting(input.Normal, brightness);

    float3 color = lerp(litColor, 1.0, input.FogFactor);

    return float4(color * 0.5, 1.0);
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    float4 texColor = SAMPLE_TEXTURE(AtlasTexture, input.TexCoord);

    float brightness = (texColor.a + input.Shininess.x) * input.Visibility;

    float3 color = texColor.rgb;
    color += ApplySpecular2(input.Normal) * input.Shininess.y;

    if (ForceShading)
    {
        color *= CalculateLighting(input.Normal, brightness);
    }

    color = lerp(color, Fog_Color, input.FogFactor);

    return float4(color, Material_Opacity);
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
