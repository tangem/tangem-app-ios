//
//  UIScrollView+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

extension UIScrollView {
    var adjustedContentOffset: CGPoint {
        get {
            let adjustedContentInset = CGPoint(
                x: -adjustedContentInset.left,
                y: -adjustedContentInset.top
            )

            return contentOffset + adjustedContentInset
        }
        set {
            let adjustedContentInset = CGPoint(
                x: -adjustedContentInset.left,
                y: -adjustedContentInset.top
            )

            contentOffset = newValue + adjustedContentInset
        }
    }
}
