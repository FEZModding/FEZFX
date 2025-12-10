// CloudShadowEffect
// 5AF26C88082387477D4B10A9D4F5FA041EDB38B04C365204CA62C4468258F8B4

static const float3 WHITE = float3(1.0, 1.0, 1.0);
static const float NORMAL_EPSILON = 0.01;
static const float VERTICAL_BLEND = 0.6;
static const float HORIZONTAL_BLEND = 0.3;
static const float BRIGHT_MIX = 0.75;

float Material_Opacity;
float4x4 Matrices_WorldViewProjection;
float3x3 Matrices_Texture;
float2 TexelOffset;
float3 DiffuseLight;
float3 BaseAmbient;
texture BaseTexture;

sampler2D BaseSampler = sampler_state
{
    Texture = <BaseTexture>;
};

struct VS_INPUT
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
    float3 Normal : NORMAL0;
};

struct VS_OUTPUT
{
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
    float3 Normal : TEXCOORD1;
};

VS_OUTPUT VS(VS_INPUT input)
{
    VS_OUTPUT output;
    
    float4 worldPos = mul(input.Position, Matrices_WorldViewProjection);
    output.Position.xy = (TexelOffset * worldPos.w) + worldPos.xy;
    output.Position.zw = worldPos.zw;
    
    float3 texCoord = float3(input.TexCoord, 1.0);
    output.TexCoord = mul(texCoord, Matrices_Texture).xy;
    output.Normal = input.Normal;
    
    return output;
}

float4 PS_Standard(VS_OUTPUT input) : COLOR0
{
    float4 texColor = tex2D(BaseSampler, input.TexCoord);
    float3 color = 1.0 - (texColor.rrr * Material_Opacity);
    
    return float4(color, 1.0);
}

float4 PS_Canopy(VS_OUTPUT input) : COLOR0
{
    float4 texColor = tex2D(BaseSampler, input.TexCoord);
    
    float3 ambientVariation = 1.0 - BaseAmbient;
    float3 ambientClamped = clamp(BaseAmbient, 0.0, 1.0);
    float normalDot = clamp(dot(input.Normal, float3(1.0, 1.0, 1.0)), 0.0, 1.0);
    float3 directionalAmbient = (normalDot * ambientVariation) + ambientClamped;
    
    float3 verticalLighting = abs(input.Normal.z) * ambientVariation.bgr;
    verticalLighting = (verticalLighting * VERTICAL_BLEND) + directionalAmbient.bgr;
    if (input.Normal.z + NORMAL_EPSILON >= 0.0)
        verticalLighting = directionalAmbient.bgr;
    
    float3 horizontalLighting = abs(input.Normal.x) * ambientVariation;
    horizontalLighting = (horizontalLighting * HORIZONTAL_BLEND) + verticalLighting.bgr;
    if (input.Normal.x + NORMAL_EPSILON < 0.0)
        verticalLighting = horizontalLighting.bgr;
    
    verticalLighting = clamp(verticalLighting, 0.0, 1.0);
    float3 canopyColor = lerp(verticalLighting.bgr, WHITE, BRIGHT_MIX);
    
    float3 halfDiffuse = 0.5 * DiffuseLight;
    float3 halfAmbient = 0.5 * BaseAmbient;
    float3 lightingDelta = (canopyColor.bgr * halfDiffuse.bgr) - halfAmbient.bgr;
    
    float shadowAttenuation = 1.0 - (texColor.r * Material_Opacity.x);
    float3 color = (lightingDelta.bgr * shadowAttenuation) + halfAmbient;
    
    return float4(color, 1.0);
}

technique TSM2
{
    pass Standard
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS_Standard();
    }

    pass Canopy
    {
        VertexShader = compile vs_2_0 VS();
        PixelShader = compile ps_2_0 PS_Canopy();
    }
}