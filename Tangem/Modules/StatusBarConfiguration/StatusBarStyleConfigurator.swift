//
//  StatusBarStyleConfigurator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import enum UIKit.UIStatusBarStyle
import enum SwiftUI.ColorScheme

protocol StatusBarStyleConfigurator {
    var selectedStatusBarStyle: UIStatusBarStyle { get }

    func setSelectedStatusBarStyle(_ statusBarStyle: UIStatusBarStyle, animated: Bool)
}

// MARK: - Convenience extensions

extension StatusBarStyleConfigurator {
    func setSelectedStatusBarColorScheme(_ colorScheme: ColorScheme?, animated: Bool) {
        switch colorScheme {
        case .light:
            setSelectedStatusBarStyle(.lightContent, animated: animated)
        case .dark:
            setSelectedStatusBarStyle(.lightContent, animated: animated)
        case .none:
            setSelectedStatusBarStyle(.default, animated: animated)
        @unknown default:
            assertionFailure("Unknown color scheme '\(String(describing: colorScheme))' received")
            setSelectedStatusBarStyle(.default, animated: animated)
        }
    }
}
