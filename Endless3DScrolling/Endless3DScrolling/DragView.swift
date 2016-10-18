//
//  DragView.swift
//  Endless3DScrolling
//
//  Created by Silvan Mosberger on 12.10.16.
//    Copyright © 2016 Silvan Mosberger. All rights reserved.
//

import MetalKit

protocol DraggingDelegate : class {
	func didDrag(dx: CGFloat, dy: CGFloat)
}

class DragView: MTKView {
	weak var draggingDelegate: DraggingDelegate?
	
	override func mouseDragged(with event: NSEvent) {
		draggingDelegate?.didDrag(dx: event.deltaX, dy: event.deltaY)
	}
}
