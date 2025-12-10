// LightmapEffect
// 0F1710E96C68066CEB9D0F033D365109C9F0F144B91244E7DEFB8E0749B64FF5

bool ShadowPass;
float3x3 Matrices_Texture;
float2 TexelOffset;
texture BaseTexture;

sampler2D BaseSampler = sampler_state
{
    Texture = <BaseTexture>;
};

struct VS_INPUT
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    output.Position = input.Position;
    output.Position.xy += TexelOffset * input.Position.w;

    float3 texCoord = float3(input.TexCoord, 1.0);
    output.TexCoord = mul(texCoord, Matrices_Texture).xy;
    
    return output;
}

float4 PS_Shadows(VS_OUTPUT input) : COLOR0
{
    float4 texColor = tex2D(BaseSampler, input.TexCoord);
    
    float3 color = ShadowPass
        ? saturate(texColor.rgb * 2.0)
        : saturate(texColor.rgb - 0.5) * 4.0 + 1.0;
    
    return float4(color, 1.0);
}

technique TSM2
{
    pass Shadows
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS_Shadows();
    }
}