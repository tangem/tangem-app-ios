//
//  StatusScreen+Modifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

// MARK: - Entry point

public extension StatusScreen where
    AssetSlot == EmptyView,
    HeaderAccessory == EmptyView,
    Details == EmptyView {
    init(
        title: String,
        description: String? = nil,
        actionTitle: String,
        action: @escaping () -> Void
    ) {
        self.init(
            title: title,
            description: description,
            actionTitle: actionTitle,
            action: action,
            assetSlot: EmptyView(),
            headerAccessory: EmptyView(),
            details: EmptyView()
        )
    }
}

// MARK: - Setupable Modifiers

public extension StatusScreen {
    func appearance(_ appearance: StatusScreenAppearance) -> Self {
        map { $0.appearance = appearance }
    }

    func secondaryAction(title: String, action: @escaping () -> Void) -> Self {
        map { $0.secondaryAction = StatusScreenSecondaryAction(title: title, action: action) }
    }

    func actionLoading(_ isLoading: Bool) -> Self {
        map { $0.isActionLoading = isLoading }
    }

    func actionDisabled(_ isDisabled: Bool) -> Self {
        map { $0.isActionDisabled = isDisabled }
    }

    func footerAxis(_ axis: StatusScreenFooterAxis) -> Self {
        map { $0.footerAxis = axis }
    }
}

// MARK: - Slot Transforms

public extension StatusScreen {
    func assetSlot<V: View>(@ViewBuilder _ content: () -> V) -> StatusScreen<V, HeaderAccessory, Details> {
        carryingSetup(StatusScreen<V, HeaderAccessory, Details>(
            title: title,
            description: description,
            actionTitle: actionTitle,
            action: action,
            assetSlot: content(),
            headerAccessory: headerAccessoryContent,
            details: detailsContent
        ))
    }

    func headerAccessory<V: View>(@ViewBuilder _ content: () -> V) -> StatusScreen<AssetSlot, V, Details> {
        carryingSetup(StatusScreen<AssetSlot, V, Details>(
            title: title,
            description: description,
            actionTitle: actionTitle,
            action: action,
            assetSlot: assetSlotContent,
            headerAccessory: content(),
            details: detailsContent
        ))
    }

    func details<V: View>(@ViewBuilder _ content: () -> V) -> StatusScreen<AssetSlot, HeaderAccessory, V> {
        carryingSetup(StatusScreen<AssetSlot, HeaderAccessory, V>(
            title: title,
            description: description,
            actionTitle: actionTitle,
            action: action,
            assetSlot: assetSlotContent,
            headerAccessory: headerAccessoryContent,
            details: content()
        ))
    }
}

// MARK: - Carrying the setup across a slot transform

private extension StatusScreen {
    /// Every slot transform builds a fresh screen, so the whole configuration has to be copied over in
    /// one place — a property carried anywhere else is a property the next one forgets.
    func carryingSetup<A: View, H: View, D: View>(_ screen: StatusScreen<A, H, D>) -> StatusScreen<A, H, D> {
        screen.map {
            $0.appearance = appearance
            $0.secondaryAction = secondaryAction
            $0.isActionLoading = isActionLoading
            $0.isActionDisabled = isActionDisabled
            $0.footerAxis = footerAxis
        }
    }
}
