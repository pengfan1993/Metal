//
//  ViewController.swift
//  01 - Metal triangle
//
//  Created by pengfan on 2021/12/13.
//

import UIKit
import QuartzCore
import Metal

class ViewController: UIViewController {

    var metalLayer: CAMetalLayer!
    var device = MTLCreateSystemDefaultDevice()
    var vertexBuffer: MTLBuffer?
    var pipelineState: MTLRenderPipelineState! = nil
    var commandQueue: MTLCommandQueue! = nil
    var timer: CADisplayLink! = nil
    
    func setupMetal() {
        metalLayer = CAMetalLayer.init()
        metalLayer.frame = view.bounds
        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        view.layer.addSublayer(metalLayer)
    }
    
    func loadData() {
        
        //命令队列
        commandQueue = device?.makeCommandQueue()
        
        
        //创建顶点数据缓冲对象
        let vertexData: [Float] = [0.0, 0.5, 0.0, -0.5, -0.5, 0.0, 0.5, -0.5, 0.0]
        
        let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
    
        vertexBuffer = device?.makeBuffer(bytes: vertexData, length: dataSize, options: .storageModeShared)
        
        
        //加载着色器
        let defaultLibrary = device?.makeDefaultLibrary()
        
        let fragmentProgram = defaultLibrary?.makeFunction(name: "basic_fragment")
        let vertexProgram = defaultLibrary?.makeFunction(name: "basic_vertex")
        
        //创建管道状态描述器
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        
        //创建管道状态对象
        do {
            try pipelineState = device?.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
        }
    }
    
    func render() {
        
        //创建渲染命令描述其
        let renderPassDescriptor = MTLRenderPassDescriptor()
        
        guard let drawable = metalLayer.nextDrawable() else {
            return
        }
        
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(221.0/255.0, 160.0/255.0, 221.0/255.0, 1.0)
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        
        //创建渲染命令编码器
        let renderEncoder = commandBuffer!.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder?.setRenderPipelineState(pipelineState)
        renderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0 )
        renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        
        renderEncoder?.endEncoding()
        
        //将命令编码器提交到命令缓冲对象中，由命令缓冲对象提交给命令队列，等待GPU执行
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
    
    @objc func gameLoop() {
        autoreleasepool {
            self.render()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMetal()
        loadData()
        
        timer = CADisplayLink(target: self, selector: #selector(ViewController.gameLoop))
        timer.add(to: .main, forMode: .default)
    }


}

