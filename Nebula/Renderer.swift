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
        
        super.init()
    }
    
    func draw(in view: MTKView) {
        let commandBuffer = commandQueue.makeCommandBuffer()!

        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: view.currentRenderPassDescriptor!)!
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.drawMeshThreads(MTLSizeMake(1, 1, 1), threadsPerObjectThreadgroup: MTLSizeMake(1, 1, 1), threadsPerMeshThreadgroup: MTLSizeMake(1, 1, 1))
        renderEncoder.endEncoding()
        
        commandBuffer.present(view.currentDrawable!)
        commandBuffer.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }

}
