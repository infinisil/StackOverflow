//
//  shaders.metal
//  Endless3DScrolling
//
//  Created by Silvan Mosberger on 12.10.16.
//  Copyright © 2016 Silvan Mosberger. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

vertex float4 basic_vertex(const device packed_float3 *data [[ buffer(0) ]],
						   const device float4x4 &trans [[ buffer(1) ]],
						   const device uint &gridSize [[ buffer(2) ]],
						   uint v_id [[ vertex_id ]],
						   uint i_id [[ instance_id ]]) {
	const float halfGridSize = (float) gridSize / 2;
	
	float4 base = float4(float3(data[v_id]), 1);
	
	base.x += i_id % gridSize - halfGridSize;
	base.z += i_id / gridSize - halfGridSize;
	
	return trans * base;
}

fragment float4 basic_fragment() {
	return 1;
}
