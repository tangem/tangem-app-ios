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
}

// MARK: - Slot Transforms

public extension StatusScreen {
    func assetSlot<V: View>(@ViewBuilder _ content: () -> V) -> StatusScreen<V, HeaderAccessory, Details> {
        StatusScreen<V, HeaderAccessory, Details>(
            title: title,
            description: description,
            actionTitle: actionTitle,
            action: action,
            appearance: appearance,
            assetSlot: content(),
            headerAccessory: headerAccessoryContent,
            details: detailsContent
        )
    }

    func headerAccessory<V: View>(@ViewBuilder _ content: () -> V) -> StatusScreen<AssetSlot, V, Details> {
        StatusScreen<AssetSlot, V, Details>(
            title: title,
            description: description,
            actionTitle: actionTitle,
            action: action,
            appearance: appearance,
            assetSlot: assetSlotContent,
            headerAccessory: content(),
            details: detailsContent
        )
    }

    func details<V: View>(@ViewBuilder _ content: () -> V) -> StatusScreen<AssetSlot, HeaderAccessory, V> {
        StatusScreen<AssetSlot, HeaderAccessory, V>(
            title: title,
            description: description,
            actionTitle: actionTitle,
            action: action,
            appearance: appearance,
            assetSlot: assetSlotContent,
            headerAccessory: headerAccessoryContent,
            details: content()
        )
    }
}
