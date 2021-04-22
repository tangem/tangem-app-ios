//
//  CGSize+.swift
//  infoScreenAnim
//
//  Created by [REDACTED_AUTHOR]
//

import CoreGraphics

internal extension CGSize {
	static func / (left: CGSize, right: CGFloat) -> CGSize {
		CGSize(width: left.width / right, height: left.height / right)
	}
	
	static func * (left: CGSize, right: CGFloat) -> CGSize {
		CGSize(width: left.width * right, height: left.height * right)
	}
}
