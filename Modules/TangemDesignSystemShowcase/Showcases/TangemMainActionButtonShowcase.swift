//
//  TangemMainActionButtonShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUI

struct TangemMainActionButtonShowcase: View {
    @State private var isBuyEnabled = true
    @State private var isSwapEnabled = false
    @State private var isSellEnabled = true
    @State private var lastEvent = "none"

    var body: some View {
        DSShowcase("MainActionButton") { controls in
            controls.toggle("Buy enabled", $isBuyEnabled)
            controls.toggle("Swap enabled", $isSwapEnabled)
            controls.toggle("Sell enabled", $isSellEnabled)
            controls.readout("Last tap", lastEvent)
        } stage: {
            HStack(spacing: 24) {
                button(.buy)
                    .disabled(!isBuyEnabled)
                button(.swap)
                    .disabled(!isSwapEnabled)
                button(.sell)
                    .disabled(!isSellEnabled)
            }
        } matrix: {
            DSShowcaseMatrix(rows: ActionKind.allCases, columns: ActionState.allCases) { kind, state in
                button(kind)
                    .disabled(state == .disabled)
            }
        }
    }

    private func button(_ kind: ActionKind) -> some View {
        TangemMainActionButton(
            title: kind.title,
            icon: kind.icon,
            action: { lastEvent = "\(kind.title) action" },
            reasonTapWhenDisabled: { lastEvent = "\(kind.title) disabled reason" }
        )
    }
}

private extension TangemMainActionButtonShowcase {
    enum ActionKind: CaseIterable {
        case buy
        case swap
        case sell

        var title: String {
            switch self {
            case .buy: "Buy"
            case .swap: "Swap"
            case .sell: "Sell"
            }
        }

        var icon: ImageType {
            switch self {
            case .buy: Assets.DesignSystem.plus
            case .swap: Assets.DesignSystem.exchangeMini
            case .sell: Assets.DesignSystem.dollar
            }
        }
    }

    enum ActionState: CaseIterable {
        case enabled
        case disabled
    }
}
#endif
