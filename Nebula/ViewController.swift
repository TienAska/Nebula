//
//  ViewController.swift
//  Nebula
//
//  Created by Tien Aska on 2024-03-29.
//

import UIKit
import MetalKit

class ViewController: UIViewController {
    var renderer: RendererMS!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let view = self.view as! MTKView
        view.device = MTLCreateSystemDefaultDevice()
        renderer = RendererMS(view: view)
        view.delegate = renderer
    }
}

