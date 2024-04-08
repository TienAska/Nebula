//
//  Renderer.swift
//  Nebula
//
//  Created by Tien Aska on 2024-03-31.
//

import Foundation
import MetalKit

class RendererMS: NSObject, MTKViewDelegate
{
    var device: MTLDevice
    var pipelineState: MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue
    
    var rendererRT: RendererRT!
    
    init?(view: MTKView) {
        self.device = view.device!
        self.commandQueue = self.device.makeCommandQueue()!
        
        let defaultLibrary = self.device.makeDefaultLibrary()!
        let meshProgram = defaultLibrary.makeFunction(name: "mesh")
        let fragProgram = defaultLibrary.makeFunction(name: "frag")
        
        let pipelineStateDesc = MTLMeshRenderPipelineDescriptor()
        pipelineStateDesc.meshFunction = meshProgram
        pipelineStateDesc.fragmentFunction = fragProgram
        pipelineStateDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        (self.pipelineState, _) = try! device.makeRenderPipelineState(descriptor: pipelineStateDesc, options: MTLPipelineOption())
        
        rendererRT = RendererRT(view: view)
        
        super.init()
    }
    
    func draw(in view: MTKView) {
        self.rendererRT.draw(in: view)
        
        let commandBuffer = commandQueue.makeCommandBuffer()!

        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: view.currentRenderPassDescriptor!)!
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setFragmentTexture(rendererRT.texture, index: 0)
        renderEncoder.drawMeshThreads(MTLSizeMake(1, 1, 1), threadsPerObjectThreadgroup: MTLSizeMake(1, 1, 1), threadsPerMeshThreadgroup: MTLSizeMake(1, 1, 1))
        renderEncoder.endEncoding()
        
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }

}

class RendererRT: NSObject, MTKViewDelegate
{
    var device: MTLDevice
    var pipelineState: MTLComputePipelineState!
    var commandQueue: MTLCommandQueue
    var texture: MTLTexture
    var accelerationStructureDescriptor: MTLPrimitiveAccelerationStructureDescriptor
    var accelerationSizes: MTLAccelerationStructureSizes
    var accelerationStructure: MTLAccelerationStructure!
    var intersectionFunctionTable: MTLIntersectionFunctionTable!
    
    struct Sphere
    {
        var center = MTLPackedFloat3Make(0.0, 0.0, 0.0)
        var radius = 1.0
        var padding = 0.0
    }
    
    init?(view: MTKView) {
        self.device = view.device!
        self.commandQueue = self.device.makeCommandQueue()!
        
        let defaultLibrary = self.device.makeDefaultLibrary()!
        let kernProgram = defaultLibrary.makeFunction(name: "kern")
        let inteProgram = defaultLibrary.makeFunction(name: "inte")
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: 8, height: 8, mipmapped: false)
        textureDescriptor.usage = [.shaderWrite, .shaderRead]
        texture = self.device.makeTexture(descriptor: textureDescriptor)!
        
        let pipelineStateDescriptor = MTLComputePipelineDescriptor()
        pipelineStateDescriptor.computeFunction = kernProgram
        let linkedFunctions = MTLLinkedFunctions()
        linkedFunctions.functions = [inteProgram!]
        pipelineStateDescriptor.linkedFunctions = linkedFunctions
        
        (self.pipelineState, _) = try! device.makeComputePipelineState(descriptor: pipelineStateDescriptor, options: MTLPipelineOption())
        
        let sphere = Sphere()
        let aabb = MTLAxisAlignedBoundingBox(min: MTLPackedFloat3Make(-1.0, -1.0, -1.0), max: MTLPackedFloat3Make(1.0, 1.0, 1.0))
        let boundingBoxBuffer = self.device.makeBuffer(bytes: [aabb], length: MemoryLayout<MTLAxisAlignedBoundingBox>.size)
        let primitiveData = self.device.makeBuffer(bytes: [sphere], length: MemoryLayout<Sphere>.size)
        
        self.accelerationStructureDescriptor = MTLPrimitiveAccelerationStructureDescriptor()
        let geometryDescriptor = MTLAccelerationStructureBoundingBoxGeometryDescriptor()
        geometryDescriptor.boundingBoxBuffer = boundingBoxBuffer
        geometryDescriptor.boundingBoxCount = 1
        geometryDescriptor.primitiveDataBuffer = primitiveData
        geometryDescriptor.primitiveDataElementSize = MemoryLayout<Sphere>.size
        geometryDescriptor.primitiveDataStride = MemoryLayout<Sphere>.stride
        self.accelerationStructureDescriptor.geometryDescriptors = [geometryDescriptor]
        
        self.accelerationSizes = self.device.accelerationStructureSizes(descriptor: accelerationStructureDescriptor)
        self.accelerationStructure = self.device.makeAccelerationStructure(size: self.accelerationSizes.accelerationStructureSize)
        
        
        let intersectionFunctionTableDescriptor = MTLIntersectionFunctionTableDescriptor()
        intersectionFunctionTableDescriptor.functionCount = 1
        self.intersectionFunctionTable = self.pipelineState.makeIntersectionFunctionTable(descriptor: intersectionFunctionTableDescriptor)
        let handle = self.pipelineState.functionHandle(function: inteProgram!)
        self.intersectionFunctionTable.setFunction(handle, index: 0)
        
        super.init()
    }
    

    
    func draw(in view: MTKView) {
        let commandBuffer = self.commandQueue.makeCommandBuffer()!
        
        let scratchBuffer = self.device.makeBuffer(length: self.accelerationSizes.buildScratchBufferSize)!
        
        let accelerationEncoder = commandBuffer.makeAccelerationStructureCommandEncoder()!
        accelerationEncoder.build(accelerationStructure: self.accelerationStructure,
                                  descriptor: self.accelerationStructureDescriptor,
                                  scratchBuffer: scratchBuffer,
                                  scratchBufferOffset: 0)
        accelerationEncoder.endEncoding()
        
        let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
        computeEncoder.setComputePipelineState(self.pipelineState)
        computeEncoder.setTexture(self.texture, index: 0)
        computeEncoder.setAccelerationStructure(self.accelerationStructure, bufferIndex: 0)
        computeEncoder.setIntersectionFunctionTable(self.intersectionFunctionTable, bufferIndex: 1)
        computeEncoder.dispatchThreadgroups(MTLSizeMake(1, 1, 1), threadsPerThreadgroup: MTLSizeMake(8, 8, 1))
        computeEncoder.endEncoding()
        
        commandBuffer.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
}
