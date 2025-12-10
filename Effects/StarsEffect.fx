// StarsEffect
// F39B3FC8087BC6BC9181EC58F48FD5E12D25A2F67721965490F15F44C930E46C

float Material_Opacity;
float4x4 Matrices_WorldViewProjection;
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
    float Brightness : TEXCOORD1;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;
    
    output.Position = mul(input.Position, Matrices_WorldViewProjection);
    output.Position.xy += TexelOffset * output.Position.w;
    
    float3 texCoord = float3(input.TexCoord, 1.0);
    output.TexCoord = mul(texCoord, Matrices_Texture).xy;
    output.Brightness = (input.Position.y + 0.05) * 16.0;
    
    return output;
}

float4 PS_P0(VS_OUTPUT input) : COLOR0
{
    float4 texColor = tex2D(BaseSampler, input.TexCoord);
    float3 starsColor = float3(texColor.rgb * Material_Opacity * input.Brightness);
    return float4(starsColor, 1.0);
}

technique TSM2
{
    pass P0
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS_P0();
    }
}