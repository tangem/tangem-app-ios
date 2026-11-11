//
//  ModalNavigation.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUIUtils

public struct ModalNavigation {
    let title: String
    let subtitle: String?
    let leading: TopNavigation.LeadingPolicy
    let actions: TopNavigation.Actions?
    let isCloseEnabled: Bool
    private(set) var closeButtonTapAction: (() -> Void)?

    public static func title(
        _ title: String,
        subtitle: String? = nil,
        leading: TopNavigation.LeadingPolicy = .none,
        actions: TopNavigation.Actions? = nil,
        isCloseEnabled: Bool = true
    ) -> ModalNavigation {
        ModalNavigation(title: title, subtitle: subtitle, leading: leading, actions: actions, isCloseEnabled: isCloseEnabled)
    }

    public static func closeButton(isCloseEnabled: Bool = true) -> ModalNavigation {
        ModalNavigation(title: "", subtitle: nil, leading: .none, actions: nil, isCloseEnabled: isCloseEnabled)
    }
}

// MARK: - Setupable

extension ModalNavigation: Setupable {
    public func onCloseButtonTap(_ action: @escaping () -> Void) -> Self {
        map { $0.closeButtonTapAction = action }
    }
}
