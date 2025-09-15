//
//  UIDelegateSetter.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import UIKit

public protocol UIDelegateSetter: AnyObject {
    associatedtype Delegate: AnyObject

    var delegate: Delegate? { get set }
    func safeSet(delegate: Delegate?)
}

public extension UIDelegateSetter {
    func safeSet(delegate newDelegate: Delegate?) {
        switch delegate {
        case .none:
            delegate = newDelegate

        case let delegate where delegate === newDelegate:
            // Already set custom delegate
            return

        // Internal SwiftUI delegate
        case let delegate:
            assertionFailure("Attempting to erase an internal SwiftUI delegate \(String(describing: delegate))")
            return
        }
    }
}

// MARK: - UINavigationController+

extension UINavigationController: UIDelegateSetter {
    public typealias Delegate = UINavigationControllerDelegate
}

// MARK: - UIScrollView+

extension UIScrollView: UIDelegateSetter {
    public typealias Delegate = UIScrollViewDelegate
}
