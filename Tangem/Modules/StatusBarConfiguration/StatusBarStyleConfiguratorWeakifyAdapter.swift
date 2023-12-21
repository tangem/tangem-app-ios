//
//  StatusBarStyleConfiguratorWeakifyAdapter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import enum UIKit.UIStatusBarStyle

final class StatusBarStyleConfiguratorWeakifyAdapter {
    typealias Adaptee = StatusBarStyleConfigurator & AnyObject

    weak var adaptee: Adaptee?
}

// MARK: - StatusBarStyleConfigurator protocol conformance

extension StatusBarStyleConfiguratorWeakifyAdapter: StatusBarStyleConfigurator {
    var selectedStatusBarStyle: UIStatusBarStyle {
        return adaptee?.selectedStatusBarStyle ?? .default
    }

    func setSelectedStatusBarStyle(_ statusBarStyle: UIStatusBarStyle, animated: Bool) {
        adaptee?.setSelectedStatusBarStyle(statusBarStyle, animated: animated)
    }
}
