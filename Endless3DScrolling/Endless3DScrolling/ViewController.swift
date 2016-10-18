//
//  ViewController.swift
//  Endless3DScrolling
//
//  Created by Silvan Mosberger on 12.10.16.
//  Copyright © 2016 Silvan Mosberger. All rights reserved.
//

import Cocoa
import MetalKit

class ViewController: NSViewController {

	var renderer : Renderer!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let dragView = view as! DragView
		
		renderer = try! Renderer(view: dragView, device: MTLCreateSystemDefaultDevice()!)
		
		dragView.draggingDelegate = renderer
	}
}

