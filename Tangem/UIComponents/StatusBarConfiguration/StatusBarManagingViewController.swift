//
//  StatusBarManagingViewController.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import UIKit

/// This root controller allows external consumers to configure system status bar style.
///
/// On iOS 16 and above status bar style is controlled by the private child VC,
/// returned in the `childForStatusBarStyle` property.
/// This is the reason why we're overriding both of these properties in this subclass of `UIViewController`.
class StatusBarManagingViewController: UIViewController {
    private var selectedStatusBarStyle: UIStatusBarStyle = .default

    override var preferredStatusBarStyle: UIStatusBarStyle {
        // In cases when the selected status bar style is unchanged (equals `.default`) - we preserve default
        // system behavior and hand over control flow to the system by returning `super.preferredStatusBarStyle` here
        guard selectedStatusBarStyle != .default else {
            return super.preferredStatusBarStyle
        }

        return selectedStatusBarStyle
    }

    override var childForStatusBarStyle: UIViewController? {
        // In cases when the selected status bar style is unchanged (equals `.default`) - we preserve default
        // system behavior and hand over control flow to the system by returning `super.childForStatusBarStyle` here
        guard selectedStatusBarStyle != .default else {
            return super.childForStatusBarStyle
        }

        return nil
    }

    func setSelectedStatusBarStyle(_ statusBarStyle: UIStatusBarStyle, animated: Bool) {
        guard statusBarStyle != selectedStatusBarStyle else { return }

        selectedStatusBarStyle = statusBarStyle
        let animationDuration = animated ? 0.3 : 0.0
        UIView.animate(withDuration: animationDuration) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
}
