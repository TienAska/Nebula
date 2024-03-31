//
//  ViewController.swift
//  Nebula
//
//  Created by Tien Aska on 2024-03-29.
//

import UIKit
import Metal

class ViewController: UIViewController {
    var device: MTLDevice!
    var metalLayer: CAMetalLayer!
    var pipelineState: MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue!
    var timer: CADisplayLink!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        device = MTLCreateSystemDefaultDevice()
        metalLayer = CAMetalLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.frame = view.layer.frame
        view.layer.addSublayer(metalLayer)
        
        let defaultLibrary = device.makeDefaultLibrary()!
        let meshProgram = defaultLibrary.makeFunction(name: "mesh")
        let fragProgram = defaultLibrary.makeFunction(name: "frag")
        
        
        let pipelineStateDesc = MTLMeshRenderPipelineDescriptor()
        pipelineStateDesc.meshFunction = meshProgram
        pipelineStateDesc.fragmentFunction = fragProgram
        pipelineStateDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        let pipelineOption = MTLPipelineOption()
        
        (pipelineState, _) = try! device.makeRenderPipelineState(descriptor: pipelineStateDesc, options: pipelineOption)
        
        commandQueue = device.makeCommandQueue()
        
        timer = CADisplayLink(target: self, selector: #selector(gameloop))
        timer.add(to: RunLoop.main, forMode: .default)
        
    }
    
    func render() {
        guard let drawable = metalLayer?.nextDrawable() else { return }
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
          red: 0.0,
          green: 104.0/255.0,
          blue: 55.0/255.0,
          alpha: 1.0)
        
        let commandBuffer = commandQueue.makeCommandBuffer()!

        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.drawMeshThreads(MTLSizeMake(1, 1, 1), threadsPerObjectThreadgroup: MTLSizeMake(1, 1, 1), threadsPerMeshThreadgroup: MTLSizeMake(1, 1, 1))
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    @objc func gameloop() {
      autoreleasepool {
        self.render()
      }
    }



}

