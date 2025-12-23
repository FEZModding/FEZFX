// TrixelParticleEffect
// E073D61F2F55F5F1EF95ED05963B56B22572E4CA5C74E9D88594B1535E943DD3

#include "BaseEffect.fxh"   // NOTE: BaseAmbient was float1 type

float4x4 InstanceData[60];

texture BaseTexture;
sampler2D BaseSampler = sampler_state
{
    Texture = <BaseTexture>;
};

struct VS_INPUT
{
    float4 Position : POSITION0;
    float3 Normal : NORMAL0;
    float2 TexCoord : TEXCOORD0;
    float InstanceIndex : TEXCOORD1;
};

struct VS_OUTPUT
{
    float2 TexCoord : TEXCOORD0;
    float4 Color : TEXCOORD1;
    float3 Normal : TEXCOORD2;
    float4 Position : POSITION0;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    int index = trunc(input.InstanceIndex);
    float4 Center = InstanceData[index][0];
    float4 Size = InstanceData[index][1];
    float4 Color = InstanceData[index][2];
    float4 TextureMatrix = InstanceData[index][3];

    output.TexCoord = input.TexCoord * TextureMatrix.xy + TextureMatrix.zw;
    
    float4x4 xform = float4x4(
        Size.x, 0.0, 0.0, 0.0,
        0.0, Size.y, 0.0, 0.0,
        0.0, 0.0, Size.z, 0.0,
        Center.x, Center.y, Center.z, 1.0
    );

    float4 position = mul(input.Position, xform);
    position.xyz += dot(position.xyz - LevelCenter, Eye) * EyeSign;

    float4 worldViewPos = TransformPositionToClip(position); 
    output.Position = ApplyTexelOffset(worldViewPos);

    output.Color = Color;
    output.Normal = input.Normal;

    return output;
}

float4 PS_Pre(VS_OUTPUT input) : COLOR0
{
    float3 tint = saturate(input.Color.rgb - 1.0);
    float3 ambient = saturate(tint.x + BaseAmbient);
    float3 invAmbient = 1.0 - BaseAmbient;
    float3 invDiffuse = tint * (1.0 - DiffuseLight);

    // Front lighting
    float normalDotLight = saturate(dot(input.Normal, 1.0));
    float3 frontLighting = normalDotLight * invAmbient + ambient;

    // Backface lighting
    float3 backLighting = abs(input.Normal.z) * invAmbient * 0.6 + frontLighting;
    float3 lighting = (input.Normal.z < -0.01) ? backLighting : frontLighting;

    // Side lighting
    float3 sideLighting = abs(input.Normal.x) * invAmbient * 0.3 + lighting;
    lighting = saturate((input.Normal.x < -0.01) ? sideLighting : lighting);

    // Apply lighting
    float3 color = (lighting * DiffuseLight * 0.5) + invDiffuse;

    // Calculate alpha
    float4 texColor = tex2D(BaseSampler, input.TexCoord);
    float alpha = (1.0 - texColor.a) * input.Color.a;

    return float4(color, alpha);
}

float4 PS_Main(VS_OUTPUT input) : COLOR0
{
    float4 texColor = tex2D(BaseSampler, input.TexCoord);
    float3 color = texColor.rgb * input.Color.rgb;
    float alpha = (1.0 - texColor.a) * input.Color.a;
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
