// BurnInPostEffect
// 42F99AA09C24C293A44E519631A57B3DA30A358692D099026E04B4907DE07AD0

float3 AcceptColor;
float3x3 Matrices_Texture;
float2 TexelOffset;
texture NewFrameTexture;
texture OldFrameTexture;

sampler2D NewFrameSampler = sampler_state
{
    Texture = <NewFrameTexture>;
};

sampler2D OldFrameSampler = sampler_state
{
    Texture = <OldFrameTexture>;
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

    output.Position.xy = (TexelOffset * input.Position.w) + input.Position.xy;
    output.Position.zw = input.Position.zw;
   
    float3 texCoord = float3(input.TexCoord, 1.0);
    output.TexCoord = mul(texCoord, Matrices_Texture).xy;

    return output;
}

float4 PS_P0(VS_OUTPUT input) : COLOR0
{
    float4 newFrame = tex2D(NewFrameSampler, input.TexCoord);
    float4 oldFrame = tex2D(OldFrameSampler, input.TexCoord);

    // Create multiplicative mask and square it for strong falloff
    float3 colorMatch = 1.0 - abs(newFrame.rgb - AcceptColor);
    float mask = colorMatch.x * colorMatch.y * colorMatch.z;
    mask = mask * mask;

    // Blend: 25% of new matched color + 75% of old frame
    float3 newContribution = AcceptColor * mask * 0.25;
    float3 result = oldFrame.rgb * 0.75 + newContribution;
    
    return float4(result, 1.0);
}

technique TSM2
{
    pass P0
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS_P0();
    }
}