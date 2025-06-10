//
//  UIResponder+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import UIKit

public extension UIResponder {
    private weak static var currentFirstResponder: UIResponder?

    static var current: UIResponder? {
        UIResponder.currentFirstResponder = nil
        UIApplication.shared.sendAction(#selector(findFirstResponder(sender:)), to: nil, from: nil, for: nil)
        return UIResponder.currentFirstResponder
    }

    @objc
    private func findFirstResponder(sender: AnyObject) {
        UIResponder.currentFirstResponder = self
    }
}
