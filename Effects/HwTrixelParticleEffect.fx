// HwTrixelParticleEffect
// 4A4BD6EB0E30FE770E35FE9BD0EE69B4DFC0CA8BFDD76EFA0A96548A30BD8C3E

#include "BaseEffect.fxh"   // NOTE: BaseAmbient was float1 type

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
    float4 Center : TEXCOORD2;
    float4 Size : TEXCOORD3;
    float4 Color : TEXCOORD4;
    float4 TextureMatrix : TEXCOORD5;
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

    output.TexCoord = input.TexCoord * input.TextureMatrix.xy + input.TextureMatrix.zw;
    
    float4x4 xform = float4x4(
        input.Size.x, 0.0, 0.0, 0.0,
        0.0, input.Size.y, 0.0, 0.0,
        0.0, 0.0, input.Size.z, 0.0,
        input.Center.x, input.Center.y, input.Center.z, 1.0
    );

    float4 position = mul(input.Position, xform);
    position.xyz += dot(position.xyz - LevelCenter, Eye) * EyeSign;

    float4 worldViewPos = TransformPositionToClip(position); 
    output.Position = ApplyTexelOffset(worldViewPos);

    output.Color = input.Color;
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
        VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS_Pre();
    }

    pass Main
    {
        VertexShader = compile vs_3_0 VS();
        PixelShader = compile ps_3_0 PS_Main();
    }
}
