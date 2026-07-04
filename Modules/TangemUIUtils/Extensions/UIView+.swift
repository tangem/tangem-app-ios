//
//  UIView+.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import UIKit

public extension UIView {
    /// Ancestors from the immediate `superview` up to the root, nearest first.
    var ancestors: [UIView] {
        var result: [UIView] = []
        var node = superview
        while let current = node {
            result.append(current)
            node = current.superview
        }
        return result
    }

    /// Enclosing scroll views, nearest first.
    var enclosingScrollViews: [UIScrollView] {
        ancestors.compactMap { $0 as? UIScrollView }
    }
}
