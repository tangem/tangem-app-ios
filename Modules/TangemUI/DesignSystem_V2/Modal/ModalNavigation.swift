//
//  ModalNavigation.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct ModalNavigation {
    let title: String
    let subtitle: String?
    let leading: TopNavigation.LeadingPolicy
    let actions: TopNavigation.Actions?
    let onClose: (() -> Void)?

    public static func title(
        _ title: String,
        subtitle: String? = nil,
        leading: TopNavigation.LeadingPolicy = .none,
        actions: TopNavigation.Actions? = nil,
        onClose: (() -> Void)? = nil
    ) -> ModalNavigation {
        ModalNavigation(title: title, subtitle: subtitle, leading: leading, actions: actions, onClose: onClose)
    }

    public static func closeButton(onClose: (() -> Void)? = nil) -> ModalNavigation {
        ModalNavigation(title: "", subtitle: nil, leading: .none, actions: nil, onClose: onClose)
    }
}
