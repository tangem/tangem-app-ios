//
//  CircularIndicatorView.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import UIKit

public enum IndicatorMode {
	case sd
	case percent
}

public class CircularIndicatorView: UIView {
	
	var currentPercentValue: Int = 0
	var totalValue: Float = 0
	var isClockwise: Bool = false
	var mode: IndicatorMode = .sd
	
	private let shapeLayer = CAShapeLayer()
	private let trackLayer = CAShapeLayer()
	
	private var boundsCenter: CGPoint {
		CGPoint(x: bounds.maxX / 2.0, y: bounds.maxY / 2.0)
	}
	private var radius: CGFloat {
		bounds.width > bounds.height ? bounds.height / 2 : bounds.width / 2
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		setupItems()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setupItems()
	}
	
	public override func layoutSubviews() {
		super.layoutSubviews()
		
		if trackLayer.position == boundsCenter { return }
		
		setupItems()
	}
	
	public func didAppear() {
		if isClockwise || mode == .percent {
			shapeLayer.strokeEnd = 0
		} else {
			shapeLayer.strokeEnd = CGFloat(1.0 - 1.0/totalValue)
		}
	}
	
	public func tickSD(remainingValue: Float) {
		let basicAnimation = CABasicAnimation(keyPath: AnimKeyPaths.strokeEnd)
		
		if isClockwise {
			basicAnimation.fromValue = (totalValue - remainingValue) / totalValue
			basicAnimation.toValue = (totalValue - remainingValue + 1.0) / totalValue
		} else {
			basicAnimation.fromValue = remainingValue / totalValue
			basicAnimation.toValue = (remainingValue - 1.0) / totalValue
		}
		
		basicAnimation.duration = 0.9
		basicAnimation.fillMode = CAMediaTimingFillMode.forwards
		basicAnimation.isRemovedOnCompletion = false
		shapeLayer.add(basicAnimation, forKey: "urSoBasic")
	}
	
	
	public func tickPercent(percentValue: Int) {
		let basicAnimation = CABasicAnimation(keyPath: AnimKeyPaths.strokeEnd)
		basicAnimation.fromValue = Float(currentPercentValue) / 100.0
		basicAnimation.toValue = Float(percentValue) / 100.0
		basicAnimation.duration = 0.2
		basicAnimation.fillMode = CAMediaTimingFillMode.forwards
		basicAnimation.isRemovedOnCompletion = false
		shapeLayer.add(basicAnimation, forKey: "urSoBasic")
		currentPercentValue = percentValue
	}
	
	private func setupItems() {
		// let's start by drawing a circle somehow
		let center = boundsCenter
		// create my track layer
		
		let circularPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: -CGFloat.pi / 2, endAngle: 1.5 * CGFloat.pi, clockwise: true)
		trackLayer.path = circularPath.cgPath
		trackLayer.strokeColor = UIColor(red: 215.0/255.0, green: 229.0/255.0, blue: 247.0/255.0, alpha: 1.0).cgColor
		trackLayer.lineWidth = 6
		trackLayer.fillColor = UIColor.clear.cgColor
		trackLayer.lineCap = CAShapeLayerLineCap.round
		
		if trackLayer.superlayer == nil {
			layer.addSublayer(trackLayer)
		}
		
		shapeLayer.path = circularPath.cgPath
		shapeLayer.strokeColor = UIColor.tngBlue.cgColor
		shapeLayer.lineWidth = 6
		shapeLayer.fillColor = UIColor.clear.cgColor
		shapeLayer.lineCap = CAShapeLayerLineCap.butt

		if shapeLayer.superlayer == nil {
			layer.addSublayer(shapeLayer)
		}
	}
	
}
