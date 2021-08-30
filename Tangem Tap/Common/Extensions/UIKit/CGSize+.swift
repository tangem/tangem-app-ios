//
//  CGSize+.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import CoreGraphics

public extension String.StringInterpolation {
    mutating func appendInterpolation(_ value: CGSize) {
        appendInterpolation(value.description)
    }
}

extension CGSize: CustomStringConvertible {
    public var description: String {
        "w: \(width.rounded()), h: \(height.rounded())"
    }
}
