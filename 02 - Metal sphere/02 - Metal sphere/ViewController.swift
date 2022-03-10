//
//  ViewController.swift
//  02 - Metal sphere
//
//  Created by pengfan on 2022/3/10.
//

import UIKit
import MetalKit
import simd

class ViewController: UIViewController {
//MARK: property
    var mkView: MTKView!
    var device: MTLDevice!
    var pipelineState: MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue!
    var mtkMesh: MTKMesh!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMTKEnvironment()
        setupView()
       
    }

    //初始化MTKView视图
    func setupView() {
        mkView = MTKView.init(frame: self.view.bounds)
        view.addSubview(mkView)
        mkView.delegate = self
        
        mkView.device = device
        mkView.framebufferOnly = true
        mkView.clearColor = MTLClearColor.init(red: 0.5, green: 0.75, blue: 0.3, alpha: 1.0)
    }
    
    //初始化一些对象，这些只需要初始化一次
    func setupMTKEnvironment() {
        
        //初始化MTLDevice，MTLDevice就是GPU的抽象表示
        guard let dev = MTLCreateSystemDefaultDevice() else {
            fatalError("could not create a command queue")
        }
        device = dev
        
        let aspect: Float = Float(view.frame.size.width / view.frame.size.height)
        
        //加载模型
        let allocator = MTKMeshBufferAllocator(device: device)
        let mdlMesh = MDLMesh(sphereWithExtent: vector_float3(0.75, 0.75 * aspect, 0.75), segments: vector_uint2(x: 100, y: 100), inwardNormals: false, geometryType: .triangles, allocator: allocator)
    
        guard let mesh = try? MTKMesh(mesh: mdlMesh, device: device) else {
            fatalError("could not create a MTKMesh")
            
        }
        mtkMesh = mesh
        
        //命令队列
        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("could not create a commandQueue")
        }
        self.commandQueue = commandQueue
        
        //加载项目中 .metal文件
        let library = try device.makeDefaultLibrary()
        
        //加载顶点函数和片段函数
        let vertexFunction = library?.makeFunction(name: "vertex_main")
        let fragmentFunction = library?.makeFunction(name: "fragment_main")
        
        //创建渲染管线
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh.vertexDescriptor)
        
        guard let state = try? device.makeRenderPipelineState(descriptor: pipelineDescriptor) else {
            fatalError("could not create a MTKRenderPipelineState")
        }
        
        pipelineState = state
    }

}

extension ViewController: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    //渲染
    func draw(in view: MTKView) {
        
        //每次绘制都需要创建的对象
        guard let commandBuffer = commandQueue.makeCommandBuffer(), let descriptor = view.currentRenderPassDescriptor, let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            fatalError()
        }
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(mtkMesh.vertexBuffers[0].buffer,
                                      offset: 0, index: 0)
        
        guard let subMesh = mtkMesh.submeshes.first else {
            fatalError()
        }
        
        renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: subMesh.indexCount, indexType: subMesh.indexType, indexBuffer: subMesh.indexBuffer.buffer, indexBufferOffset: 0)
        
       //提交给GPU渲染
        renderEncoder.endEncoding()
        
        guard let drawable = mkView.currentDrawable else {
            fatalError()
        }
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
