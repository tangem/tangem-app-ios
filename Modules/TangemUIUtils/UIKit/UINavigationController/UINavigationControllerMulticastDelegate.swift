//
//  UINavigationControllerMulticastDelegate.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import UIKit
import TangemUIUtilsObjC

public extension UINavigationController {
    /// Installs a multicast navigation controller delegate, preserving the existing delegate.
    ///
    /// This method captures the current `delegate` as the *original delegate* and replaces it
    /// with the provided multicast delegate. The multicast delegate will forward delegate
    /// callbacks to both the original delegate and a custom delegate.
    ///
    /// - Note: if the navigation controller is already using a `UINavigationControllerMulticastDelegate`, this method performs no action.
    ///
    /// - Important:
    ///   - The navigation controller is expected to already have a non-`nil` delegate
    ///     (for example, a delegate installed by `NavigationStack`).
    ///   - The multicast delegate must be retained strongly by the caller.
    ///
    /// - Parameter multicastDelegate: A multicast delegate that injects additional behavior into the navigation controller’s delegate callbacks.
    func set(multicastDelegate: UINavigationControllerMulticastDelegate?) {
        guard let multicastDelegate, let originalDelegate = delegate else {
            assertionFailure("Invalid delegate setup. Expected to have non-nil delegate objects.")
            return
        }

        if originalDelegate is UINavigationControllerMulticastDelegate {
            return
        }

        multicastDelegate.set(originalDelegate: originalDelegate)
        delegate = multicastDelegate
    }
}

public final class UINavigationControllerMulticastDelegate: NSProxyMulticastDelegate<UINavigationControllerDelegate>,
    UINavigationControllerDelegate,
    ObservableObject {}
