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

struct Sphere { packed_float3 center; float radius; float padding; };

struct FragmentData {
    VertexData vert;
    PrimitiveData prim;
};

[[fragment]]
float4 frag(FragmentData in [[stage_in]],
            metal::raytracing::primitive_acceleration_structure as [[buffer(0)]],
            metal::raytracing::intersection_function_table<> ft [[buffer(1)]])
{
    float u = in.vert.uv.x;
    float v = in.vert.uv.y;
    
    metal::raytracing::intersector<> i;
    typename metal::raytracing::intersector<>::result_type intersection;
    
    metal::raytracing::ray r;
    r.direction = float3(u, v, 1.0f);
    r.origin = float3(0.0f, 0.0f, 0.0f);
    float4 payload(0.8f, 0.0f, 0.1f, 1.0f);
    intersection = i.intersect(r, as, ft, payload);
    Sphere sphere = *(const device Sphere*)intersection.primitive_data;
    
    if(intersection.primitive_data == nullptr)
    {
        return float4(u, v, 0.0f, 1.0f);
    }
    else
    {
//        payload.b = sphere.padding;
        return payload;
    }
}

struct BoundingBoxResult {
    bool accept [[accept_intersection]];
    float distance [[distance]];
};

[[intersection(bounding_box)]]
BoundingBoxResult inte(float3 origin [[origin]],
                       float3 direction [[direction]],
                       const device void* data [[primitive_data]],
                       ray_data float4& color [[payload]])
{
    BoundingBoxResult ret;
    ret.accept = true;
    ret.distance = 0.4f;
    color = float4(1.0f, 0.0f, 1.0f, 1.0f);
    Sphere sphere = *(const device Sphere*) data;
    sphere.padding = 0.5f;
    
    return ret;
}

struct Uniforms {
    unsigned int width;
    unsigned int height;
};

[[kernel]]
void kern(uint2 tid [[thread_position_in_threadgroup]],
          uint2 size [[threads_per_threadgroup]],
          constant Uniforms& uniforms,
          metal::texture2d<float, metal::access::write> dstTex [[texture(0)]],
          metal::raytracing::primitive_acceleration_structure as [[buffer(0)]],
          metal::raytracing::intersection_function_table<> ft [[buffer(1)]])
{
    metal::raytracing::intersector<> i;
    typename metal::raytracing::intersector<>::result_type intersection;
    
    float u = (float)tid.x / size.x;
    float v = (float)tid.y / size.y;
    
    metal::raytracing::ray r;
    r.direction = float3(u, v, 1.0f);
    r.origin = float3(0.0f, 0.0f, 0.0f);
    float4 payload(0.8f, 0.0f, 0.1f, 1.0f);
    intersection = i.intersect(r, as, ft, payload);
    Sphere sphere = *(const device Sphere*)intersection.primitive_data;
    
    

    if(intersection.primitive_data == nullptr)
    {
        dstTex.write(float4(u, v, 0.0f, 1.0f), tid);
    }
    else
    {
//        payload.b = sphere.padding;
        dstTex.write(payload, tid);
    }
}
