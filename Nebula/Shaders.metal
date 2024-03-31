//
//  Shaders.metal
//  Nebula
//
//  Created by Tien Aska on 2024-03-30.
//

#include <metal_stdlib>

struct VertexData    { float4 position [[position]]; float2 uv; };
struct PrimitiveData { float4 color; };

using triangle_mesh_t = metal::mesh<
                                    VertexData,               // Vertex type
                                    PrimitiveData,            // Primitive type
                                    3,                       // Maximum vertices
                                    1,                        // Maximum primitives
                                    metal::topology::triangle // Topology
>;

[[mesh]]
void mesh(triangle_mesh_t outputMesh, uint tid [[thread_index_in_threadgroup]]) {
    outputMesh.set_vertex(0, VertexData{float4(-1.0f, 1.0f, 0.0f, 1.0f), float2(0.0f, 0.0f)});
    outputMesh.set_index(0, 0);
    outputMesh.set_vertex(1, VertexData{float4(-1.0f, -3.0f, 0.0f, 1.0f), float2(0.0f, 2.0f)});
    outputMesh.set_index(1, 1);
    outputMesh.set_vertex(2, VertexData{float4(3.0f, 1.0f, 0.0f, 1.0f), float2(2.0f, 0.0f)});
    outputMesh.set_index(2, 2);
    outputMesh.set_primitive(0, PrimitiveData{float4(1.0f, 1.0f, 1.0f, 1.0f)});
    outputMesh.set_primitive_count(1);
}

struct FragmentData {
    VertexData vert;
    PrimitiveData prim;
};

[[fragment]]
float4 frag(FragmentData in [[stage_in]]) {
    return in.prim.color * float4(in.vert.uv, 0.0f, 1.0f);
}
