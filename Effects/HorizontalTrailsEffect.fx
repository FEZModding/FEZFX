// HorizontalTrailsEffect
// 7DF5461DCCFCFEB4B98ACF82D9E9BA368CB88530C40B9F7E142D66F8411348CD

#include "BaseEffect.fxh"

float Timing;
float3 Right;

struct VS_INPUT
{
    float4 Position : POSITION0;
    // Color.r:  Random [0-1] for color phase selection (0=red, 0.33=green, 0.67=blue)
    // Color.g:  Unused
    // Color.b:  Random [0-1] for blend/opacity intensity
    // Color.a:  0 = anchor point (fixed), 1 = trail point (stretches)
    float4 Color : COLOR0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float4 Color : TEXCOORD0;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float timing = pow(Timing / 6.0, 4.0);
    float mixFactor = timing * 0.1;
    float fadeFactor = saturate(pow(timing * 0.4, 3.0) * 0.5);

    // Blend intensity (sqrt curve for softer falloff)
    float blend = saturate(lerp(pow(input.Color.b, 4), sqrt(input.Color.b), mixFactor));

    // Trail offset
    float offset = min(pow(abs(blend * timing * 0.5), 10.0) * 50.0, 750.0);
    float4 position = input.Position;
    if (input.Color.a == 1.0)
    {
        position.xyz -= Right * offset;
    }

    // Position transform
    float4 worldViewPos = TransformPositionToClip(position);
    output.Position = ApplyTexelOffset(worldViewPos);

    // Visibility check
    float facing = dot(input.Position.xyz, Eye);
    float visible = (facing >= 0.0) ? 1.0 : 0.0;
    output.Color.a = visible;

    // Color phase (quantized to 3 levels: 0, 2, 4)
    float phase = floor(saturate(floor(input.Color.r * 3.0) / 3.0) * 6.0);
    phase = phase - 6.0 * floor(phase / 6.0);  // wrap 6 -> 0

    // Select RGB based on phase (6-phase color wheel, only 0/2/4 used)
    float3 color;
    float full = blend;
    float dim = blend * (1.0 - fadeFactor);
    
    if (phase < 1.0)
    {
        color = float3(full, dim, dim);      // Phase 0: Red
    }
    else if (phase < 3.0)
    {
        color = float3(dim, full, dim);      // Phase 2: Green
    }
    else
    {
        color = float3(dim, dim, full);      // Phase 4: Blue
    }

    // Brightness: anchor points brighter (1.58), trail points dimmer (0.25)
    float brightness = (1.0 - input.Color.a) * (4.0 / 3.0) + 0.25;
    output.Color.xyz = color * brightness * visible;

    return output;
}

float4 PS(VS_OUTPUT input) : COLOR0
{
    return input.Color;
}

technique TSM2
{
    pass Main
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS();
    }
}
