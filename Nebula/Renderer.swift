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
    
    init?(view: MTKView) {
        self.device = view.device!
        self.commandQueue = self.device.makeCommandQueue()!
        
        let defaultLibrary = self.device.makeDefaultLibrary()!
        let kernProgram = defaultLibrary.makeFunction(name: "kern")
//        let inteProgram = defaultLibrary.makeFunction(name: "inte")
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: 8, height: 8, mipmapped: false)
        textureDescriptor.usage = [.shaderWrite, .shaderRead]
        texture = self.device.makeTexture(descriptor: textureDescriptor)!
        
        let pipelineStateDescriptor = MTLComputePipelineDescriptor()
        pipelineStateDescriptor.computeFunction = kernProgram
        
        (self.pipelineState, _) = try! device.makeComputePipelineState(descriptor: pipelineStateDescriptor, options: MTLPipelineOption())
        
        super.init()
    }
    
    func draw(in view: MTKView) {
//        let accelerationStructureDescriptor = MTLPrimitiveAccelerationStructureDescriptor()
//        let geomtryDescriptor = MTLAccelerationStructureBoundingBoxGeometryDescriptor()
//        geomtryDescriptor.boundingBoxBuffer = boundingBoxBuffer
//        geomtryDescriptor.boundingBoxCount = boundingBoxCount
//        accelerationStructureDescriptor.geometryDescriptors = [geomtryDescriptor]
        
        let commandBuffer = self.commandQueue.makeCommandBuffer()!
        
        let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
        computeEncoder.setComputePipelineState(self.pipelineState)
        computeEncoder.setTexture(self.texture, index: 0)
        computeEncoder.dispatchThreadgroups(MTLSizeMake(1, 1, 1), threadsPerThreadgroup: MTLSizeMake(8, 8, 1))
        computeEncoder.endEncoding()
        
        commandBuffer.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
}
