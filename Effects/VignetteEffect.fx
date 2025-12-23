// VignetteEffect
// 0215FF82383DB0B69F57EDCD929FEDC5EBC1B0182736D4C4F30E9F12C3816F49

float Material_Opacity;
float SinceStarted;
float2 TexelOffset;

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
    output.TexCoord = input.TexCoord;

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    float horizontalPower = clamp(pow(abs(3.0 * SinceStarted), 30.0), 4.0, 1000000.0);
    float verticalPower = clamp(pow(abs(10.0 * SinceStarted), 15.0), 4.0, 1000000.0);
    
    float2 offset = input.TexCoord - 0.5;
    float2 offsetSq = offset * offset;
    float2 falloff = 1.0 - (offsetSq * 0.6);
    
    float vignetteX = pow(abs(falloff.x), horizontalPower);
    float vignetteY = pow(abs(falloff.y), verticalPower);
    float vignette = (vignetteX * vignetteY) - 1.0;
    
    float3 color = (Material_Opacity * vignette) + 1.0;
    return float4(color, 1.0);
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}