//
//  Renderer.swift
//  Endless3DScrolling
//
//  Created by Silvan Mosberger on 12.10.16.
//    Copyright © 2016 Silvan Mosberger. All rights reserved.
//

import MetalKit
import GLKit

extension GLKMatrix4 {
	static func *(lhs: GLKMatrix4, rhs: GLKMatrix4) -> GLKMatrix4 {
		return GLKMatrix4Multiply(lhs, rhs)
	}
}

typealias Point = (Float, Float, Float)

let a : Point = (0, 0, 0)
let b : Point = (0, 0, 1)
let c : Point = (1, 0, 1)
let d : Point = (1, 0, 0)
let top : Point = (0.5, 0.3, 0.5)

// Triangles forming the top half of an octahedron
var triangles : [Point] = [
	a, top, b,
	b, top, c,
	c, top, d,
	d, top, a,
]

class Renderer: NSObject, MTKViewDelegate, DraggingDelegate {
	let queue : MTLCommandQueue
	let pipe : MTLRenderPipelineState
	
	/// Stores the base vertices for the triangles
	let vertexBuffer : MTLBuffer
	
	/// Stores the transformation matrix
	let transformBuffer : MTLBuffer
	
	/// Simple setter and getter for the GLKMatrix4 stored in transformBuffer
	var trans : GLKMatrix4 {
		get {
			return transformBuffer.contents().bindMemory(to: GLKMatrix4.self, capacity: 1)[0]
		}
		set {
			transformBuffer.contents().bindMemory(to: GLKMatrix4.self, capacity: 1)[0] = newValue
		}
	}
	
	/// Grid will have the dimensions gridSize x gridSize
	var gridSize : CUnsignedInt = 5
	
	/// User x position, always within [0, 1)
	var x : Float = 0
	/// User y position, always within [0, 1)
	var z : Float = 0
	
	let fovDegrees : Float = 85
	let near : Float = 0.001
	let far : Float = 10
	let tiltDegrees : Float = 60
	let distance : Float = 1
	let draggingSpeed : Float = 0.01
	
	init(view: MTKView, device: MTLDevice) throws {
		view.device = device
		
		queue = device.makeCommandQueue()
		
		let library = device.newDefaultLibrary()
		
		let pipeDesc = MTLRenderPipelineDescriptor()
		pipeDesc.colorAttachments[0].pixelFormat = view.colorPixelFormat
		pipeDesc.vertexFunction = library?.makeFunction(name: "basic_vertex")
		pipeDesc.fragmentFunction = library?.makeFunction(name: "basic_fragment")
		
		pipe = try device.makeRenderPipelineState(descriptor: pipeDesc)
		
		// Load triangles into buffer
		vertexBuffer = device.makeBuffer(
			bytes: &triangles, length: MemoryLayout<Point>.stride * triangles.count, options: [])
		transformBuffer = device.makeBuffer(length: MemoryLayout<GLKMatrix4>.size, options: [])
		
		super.init()
				
		view.delegate = self
	}
	
	func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
	
	/// Calculates the transformation matrix for
	func updateTransform(size: CGSize) {
		let perspective = GLKMatrix4MakePerspective(
			GLKMathDegreesToRadians(fovDegrees),
			Float(size.width / size.height),
			near, far)
		let moveBack = GLKMatrix4MakeTranslation(0, 0, -distance)
		let tilt = GLKMatrix4MakeXRotation(GLKMathDegreesToRadians(tiltDegrees))
		let position = GLKMatrix4MakeTranslation(x, 0, z)
		trans = perspective * moveBack * tilt * position
	}
	
	func didDrag(dx: CGFloat, dy: CGFloat) {
		// Move user position on drag, adding 1 to not get below 0
		x += Float(dx) * draggingSpeed + 1
		z += Float(dy) * draggingSpeed + 1
		
		x.formTruncatingRemainder(dividingBy: 1)
		z.formTruncatingRemainder(dividingBy: 1)
	}
	
	func draw(in view: MTKView) {
		guard
			let drawable = view.currentDrawable,
			let pass = view.currentRenderPassDescriptor
		else { return }
		
		updateTransform(size: view.frame.size)
		
		let commands = queue.makeCommandBuffer()
		let encoder = commands.makeRenderCommandEncoder(descriptor: pass)
		
		encoder.setRenderPipelineState(pipe)
		encoder.setTriangleFillMode(.lines)

		encoder.setVertexBuffer(vertexBuffer, offset: 0, at: 0)
		encoder.setVertexBuffer(transformBuffer, offset: 0, at: 1)
		encoder.setVertexBytes(&gridSize, length: MemoryLayout<CUnsignedInt>.size, at: 2)
		
		encoder.drawPrimitives(
			type: .triangle,
			vertexStart: 0,
			vertexCount: triangles.count,
			instanceCount: Int(gridSize) * Int(gridSize))
			// This is the important bit, we're gonna draw gridSize x gridSize instances
		
		encoder.endEncoding()
		commands.present(drawable)
		commands.commit()
	}
}
