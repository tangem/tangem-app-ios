//
//  ModalStatus+Modifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

// MARK: - Entry points

public extension ModalStatus where Asset == EmptyView, ExtraBottom == EmptyView, Details == EmptyView {
    init(_ appearance: ModalStatusAppearance, title: String, description: String? = nil) {
        self.init(
            appearance: appearance,
            title: title,
            description: description,
            assetSlot: EmptyView(),
            extraBottom: EmptyView(),
            details: EmptyView()
        )
    }
}

public extension ModalStatus where ExtraBottom == EmptyView, Details == EmptyView {
    init(title: String, description: String? = nil, @ViewBuilder asset: () -> Asset) {
        self.init(
            appearance: nil,
            title: title,
            description: description,
            assetSlot: asset(),
            extraBottom: EmptyView(),
            details: EmptyView()
        )
    }
}

// MARK: - Setupable Modifiers

public extension ModalStatus {
    func titleStyle(_ style: ModalStatusTitleStyle) -> Self {
        map { $0.titleStyle = style }
    }

    func actions(primary: Button, secondary: Button? = nil) -> Self {
        map { $0.actions = ModalStatusActions(primary: primary, secondary: secondary) }
    }
}

// MARK: - Slot Transforms

public extension ModalStatus {
    func extraBottom<V: View>(
        @ViewBuilder _ content: () -> V
    ) -> ModalStatus<Asset, ModalStatusExtraBottomSlot<V>, Details> {
        carryingSetup(ModalStatus<Asset, ModalStatusExtraBottomSlot<V>, Details>(
            appearance: appearance,
            title: title,
            description: description,
            assetSlot: assetContent,
            extraBottom: ModalStatusExtraBottomSlot(content: content()),
            details: detailsContent
        ))
    }

    func details<V: View>(
        @ViewBuilder _ content: () -> V
    ) -> ModalStatus<Asset, ExtraBottom, ModalStatusDetailsSlot<V>> {
        carryingSetup(ModalStatus<Asset, ExtraBottom, ModalStatusDetailsSlot<V>>(
            appearance: appearance,
            title: title,
            description: description,
            assetSlot: assetContent,
            extraBottom: extraBottomContent,
            details: ModalStatusDetailsSlot(content: content())
        ))
    }
}

// MARK: - Carrying the setup across a slot transform

private extension ModalStatus {
    func carryingSetup<A: View, E: View, D: View>(_ status: ModalStatus<A, E, D>) -> ModalStatus<A, E, D> {
        status.map {
            $0.titleStyle = titleStyle
            $0.actions = actions
        }
    }
}
