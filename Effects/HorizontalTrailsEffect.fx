// HorizontalTrailsEffect
// 7DF5461DCCFCFEB4B98ACF82D9E9BA368CB88530C40B9F7E142D66F8411348CD

#include "BaseEffect.fxh"

float Timing;
float3 Right;

struct VS_INPUT
{
    float4 Position : POSITION0;
    float4 Color : COLOR0;      // HSV Color
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float4 Color : TEXCOORD0;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;

    float3 hsvColor = input.Color.rgb;
    float s = pow(Timing / 6.0, 4.0);

    float hue = floor(hsvColor[0] * 3.0) / 3.0;
	float saturation = pow(s / 2.5, 3.0) / 2.0;
	float value = lerp(pow(abs(hsvColor[2]), 4.0), sqrt(hsvColor[2]), s / 10.0);
    float3 color = HSV_RGB(saturate(hue), saturate(saturation), saturate(value));
    
    float4 position = input.Position;
    if (input.Color.a == 1.0)
	{
		float pf = min(pow(abs(hsvColor[2] * s / 2.0), 10.0) * 50.0, 750.0);
		position.xyz += pf * -Right;
	}
    float4 worldViewPos = TransformPositionToClip(position);
    output.Position = ApplyTexelOffset(worldViewPos);

    output.Color = float4(color * ((1.0 - input.Color.a) / 0.75 + 0.25), 1.0);
    if (dot((float3)input.Position, Eye) < 0.0)
    {
        output.Color = 0.0;
    }

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
