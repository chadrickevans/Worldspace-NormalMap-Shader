Shader "OMAGX Studios/WorldSpace Normal Map Shader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
	_BumpMap("Bumpmap", 2D) = "bump" {}
	_BumpScale("Normal Scale", Float) = 1
	_Scale("Texture Scale", Float) = 0.1

    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        
        #pragma surface surf Lambert fullforwardshadows vertex:vert
		
        #pragma target 3.0
	#include "UnityCG.cginc"

        sampler2D _MainTex;
	sampler2D _BumpMap;
	fixed4 _Color, _FHLColor;
	float _useSM;
	float _Scale;
	float _BumpScale;
	float _rotation;

        struct Input
        {
            	float2 uv_MainTex;
		float3 localCoord;
		float3 localNormal;
		float3 worldNormal;
		float3 worldPos;
		INTERNAL_DATA
        };

	half3 blend_rnm(half3 bA, half3 bB)
	{
		bA.z += 1; bB.xy = -bB.xy;
		return bA * dot(bA, bB) / bA.z - bB;
	}


	float3 WorldToTangentNormalVector(Input IN, float3 normal) 
	{
		float3 W2T0 = WorldNormalVector(IN, float3(1, 0, 0));
		float3 W2T1 = WorldNormalVector(IN, float3(0, 1, 0));
		float3 W2T2 = WorldNormalVector(IN, float3(0, 0, 1));
		float3x3 t2w = float3x3(W2T0, W2T1, W2T2);
		return normalize(mul(t2w, normal));
	}

	void vert(inout appdata_full v, out Input data)
	{
		UNITY_INITIALIZE_OUTPUT(Input, data);
		data.localCoord = v.vertex.xyz;
		data.localNormal = v.normal.xyz;
		data.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
	}


        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutput  o)
        {
		IN.worldNormal = WorldNormalVector(IN, float3(0, 0, 1));
		float3 blending = normalize(abs(IN.worldNormal));
		blending /= dot(blending, (float3)1);

		// Tri
		float2 tx = IN.worldPos.zy * (_Scale);
		float2 ty = IN.worldPos.xz * (_Scale);
		float2 tz = IN.worldPos.xy * (_Scale);

		// Color
		half4 cx = tex2D(_MainTex, tx) * blending.x;
		half4 cy = tex2D(_MainTex, ty) * blending.y;
		half4 cz = tex2D(_MainTex, tz) * blending.z;
		half4 finalcolor = (cx + cy + cz) * _Color;

		//Normal
		half4 nx = tex2D(_BumpMap, tx) * blending.x;
		half4 ny = tex2D(_BumpMap, ty) * blending.y;
		half4 nz = tex2D(_BumpMap, tz) * blending.z;

		o.Normal = UnpackScaleNormal(nx + ny + nz, _BumpScale);
		float3 wnorm = WorldNormalVector(IN, o.Normal);

		//Execution
		o.Albedo = finalcolor.rgb;
            	o.Alpha = finalcolor.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
