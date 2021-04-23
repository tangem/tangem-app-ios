//
//  CGPointCGSize+Ext.swift
//  infoScreenAnim
//
//  Created by [REDACTED_AUTHOR]
//

import CoreGraphics

internal extension CGPoint {
	static func + (left: CGPoint, right: CGPoint) -> CGPoint {
		CGPoint(x: left.x + right.x, y: left.y + right.y)
	}
	
	static func + (left: CGPoint, right: CGSize) -> CGPoint {
		CGPoint(x: left.x + right.width, y: left.y + right.height)
	}
	
	static func + (left: CGPoint, right: CGFloat) -> CGPoint {
		CGPoint(x: left.x + right, y: left.y + right)
	}
	
	static func - (left: CGPoint, right: CGPoint) -> CGPoint {
		CGPoint(x: left.x - right.y, y: left.x - right.y)
	}
	
	static func +< (left: CGPoint, right: CGPoint) -> CGPoint {
		CGPoint(x: left.x + right.x, y: left.y)
	}
	
	static func +< (left: CGPoint, right: CGFloat) -> CGPoint {
		CGPoint(x: left.x + right, y: left.y)
	}
	
	static func +^ (left: CGPoint, right: CGPoint) -> CGPoint {
		CGPoint(x: left.x, y: left.y + right.y)
	}
	
	static func +^ (left: CGPoint, right: CGFloat) -> CGPoint {
		CGPoint(x: left.x, y: left.y + right)
	}
	
	static func -< (left: CGPoint, right: CGPoint) -> CGPoint {
		CGPoint(x: left.x - right.x, y: left.x)
	}
	
	static func -< (left: CGPoint, right: CGFloat) -> CGPoint {
		CGPoint(x: left.x - right, y: left.y)
	}
	
	static func -^ (left: CGPoint, right: CGPoint) -> CGPoint {
		CGPoint(x: left.x, y: left.y - right.y)
	}
	
	static func -^ (left: CGPoint, right: CGFloat) -> CGPoint {
		CGPoint(x: left.x, y: left.y - right)
	}
}
