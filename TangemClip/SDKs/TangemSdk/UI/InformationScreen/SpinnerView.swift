//
//  SpinnerView.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import UIKit

class SpinnerView: UIView {
	
	private(set) var shouldAnimateSpinner = false
	
	private var radius: CGFloat {
		return frame.width > frame.height ? frame.height / 2 : frame.width / 2
	}
	
	private var isSpinnerIdle = true
	private var stroke: CGFloat = 6
	private var padding: CGFloat = 0
	
	init(frame: CGRect, lineHeight: CGFloat) {
		super.init(frame: frame)
		stroke = lineHeight
		backgroundColor = .clear
	}
	
	required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }
	
	override func draw(_ rect: CGRect) {
		super.draw(rect)
		drawSpinner(outerRadius: radius - padding, innerRadius: radius - stroke - padding, resolution: 1)
	}
	
	func startAnimation() {
		shouldAnimateSpinner = true
		animateRotation()
	}
	
	func stopAnimation() {
		shouldAnimateSpinner = false
	}
	
	private func animateRotation() {
		guard (alpha > 0 || shouldAnimateSpinner), isSpinnerIdle else { return }
		
		isSpinnerIdle = false
		
		UIView.animate(withDuration: 0.5, delay: 0, options: [.curveLinear], animations: {
			self.transform = self.transform.rotated(by: .pi)
		}, completion: { _ in
			self.isSpinnerIdle = true
			self.animateRotation()
		})
	}
	
	/// Resolution should be between 0.1 and 1
	private func drawSpinner(outerRadius: CGFloat, innerRadius: CGFloat, resolution: Float) {
		guard let context = UIGraphicsGetCurrentContext() else { return }
		
		context.saveGState()
		context.translateBy(x: self.bounds.midX, y: self.bounds.midY) //Move context to center
		
		let subdivisions:CGFloat = CGFloat(resolution * 512) //Max subdivisions of 512
		
		let innerHeight = (CGFloat.pi * innerRadius) / subdivisions //height of the inner wall for each segment
		let outterHeight = (CGFloat.pi * outerRadius) / subdivisions
		
		let segment = UIBezierPath()
		segment.move(to: CGPoint(x: innerRadius, y: -innerHeight / 2))
		segment.addLine(to: CGPoint(x: innerRadius, y: innerHeight / 2))
		segment.addLine(to: CGPoint(x: outerRadius, y: outterHeight / 2))
		segment.addLine(to: CGPoint(x: outerRadius, y: -outterHeight / 2))
		segment.close()
		
		//Draw each segment and rotate around the center
		for i in 0 ..< Int(ceil(subdivisions)) {
			UIColor.tngBlue.withAlphaComponent(CGFloat(i) / subdivisions).set()
			segment.fill()
			//let lineTailSpace = CGFloat.pi*2*outerRadius/subdivisions  //The amount of space between the tails of each segment
			let lineTailSpace = CGFloat.pi * 2 * outerRadius / subdivisions
			segment.lineWidth = lineTailSpace //allows for seemless scaling
			segment.stroke()
			
			//Rotate to correct location
			let rotate = CGAffineTransform(rotationAngle: -(CGFloat.pi * 2 / subdivisions)) //rotates each segment
			segment.apply(rotate)
		}
		
		context.translateBy(x: -self.bounds.midX, y: -self.bounds.midY) //Move context back to original position
		context.restoreGState()
	}
}
