//
//  FixedSizeButtonWithIconInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets

struct FixedSizeButtonWithIconInfo {
    typealias ButtonAction = () -> Void
    let title: String
    let icon: ImageType
    let style: FixedSizeButtonWithLeadingIcon.Style
    let shouldShowBadge: Bool
    let action: ButtonAction
    let longPressAction: ButtonAction?
    let loading: Bool
    let disabled: Bool
    let accessibilityIdentifier: String?

    init(
        title: String,
        icon: ImageType,
        loading: Bool = false,
        disabled: Bool = false,
        style: FixedSizeButtonWithLeadingIcon.Style = .default,
        shouldShowBadge: Bool = false,
        action: @escaping ButtonAction,
        longPressAction: ButtonAction? = nil,
        accessibilityIdentifier: String? = nil
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.shouldShowBadge = shouldShowBadge
        self.loading = loading
        self.disabled = disabled
        self.action = action
        self.longPressAction = longPressAction
        self.accessibilityIdentifier = accessibilityIdentifier
    }
}

extension FixedSizeButtonWithIconInfo: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(icon)
        hasher.combine(loading)
        hasher.combine(disabled)
        hasher.combine(shouldShowBadge)
        hasher.combine(style)
    }

    static func == (lhs: FixedSizeButtonWithIconInfo, rhs: FixedSizeButtonWithIconInfo) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension FixedSizeButtonWithIconInfo: Identifiable {
    var id: Int { hashValue }
}
