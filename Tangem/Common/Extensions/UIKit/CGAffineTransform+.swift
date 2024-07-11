//
//  CGAffineTransform+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import CoreGraphics

extension CGAffineTransform {
    static func scaleTransform(
        for bounds: CGSize,
        scaledBy scale: CGPoint,
        aroundAnchorPoint relativeAnchorPoint: CGPoint,
        translationCoefficient: CGFloat = 1.0
    ) -> CGAffineTransform {
        let anchorPoint = CGPoint(x: bounds.width * relativeAnchorPoint.x, y: bounds.height * relativeAnchorPoint.y)
        return CGAffineTransform.identity
            .translatedBy(x: anchorPoint.x * translationCoefficient, y: anchorPoint.y * translationCoefficient)
            .scaledBy(x: scale.x, y: scale.y)
            .translatedBy(x: -anchorPoint.x * translationCoefficient, y: -anchorPoint.y * translationCoefficient)
    }
}
