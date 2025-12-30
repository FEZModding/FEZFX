// ScanlineEffect
// 4C93D5D8870A4D52F2543721E17AD048345A450510250B93276564CAECC992BC

#include "BaseEffect.fxh"

static const float SCANLINE_FREQ = 300.0 * PI;

DECLARE_TEXTURE(BaseTexture);

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

    output.Position = ApplyTexelOffset(input.Position);
    output.TexCoord = input.TexCoord;

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    // Barrel distortion
    float2 offset = input.TexCoord - 0.5;
    float distSq = dot(offset, offset);
    float2 bulged = offset * 2.0 + 0.5;
    float distortion = pow(abs(distSq), 1.5);

    // Sample texture
    float2 texCoord = lerp(input.TexCoord, bulged, distortion);
    float4 texColor = SAMPLE_TEXTURE(BaseTexture, texCoord);

    // Scanline phase with RGB offset
    float scanlinePhase = texCoord.y * SCANLINE_FREQ + Time * 2.0;
    float3 phases = scanlinePhase + float3(0.0, 1.0, 2.0);

    // Apply scanline modulation
    float3 scanline = cos(phases) * 0.5 + 0.8;
    float3 color = texColor.rgb * scanline;

    return float4(color, Material_Opacity);
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}