//
//  ToastSnapshotScenario.swift
//  TangemSnapshotTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemSnapshotTestSupport
import TangemUI

enum ToastSnapshotScenario: String, SnapshotScenario {
    case appearances
    case options
    case multiline
    case appearancesRTL
    case optionsLargeText
    case multilineLargeText

    var layoutDirection: LayoutDirection {
        self == .appearancesRTL ? .rightToLeft : .leftToRight
    }

    var dynamicTypeSize: DynamicTypeSize {
        switch self {
        case .optionsLargeText, .multilineLargeText: .xxxLarge
        case .appearances, .options, .multiline, .appearancesRTL: .large
        }
    }

    @MainActor
    @ViewBuilder
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch self {
            case .appearances, .appearancesRTL:
                ToastView("Address copied", appearance: .neutral(icon: DesignSystem.Icons.Checkmark.regular20))
                ToastView("Couldn't connect. Try again", appearance: .error)
                ToastView("Balance is currently hidden", appearance: .info)
                ToastView("Transaction sent", appearance: .success)
            case .options, .optionsLargeText:
                ToastView("Promo code copied")
                ToastView("Token hidden", appearance: .neutral(icon: DesignSystem.Icons.Checkmark.regular20))
                    .action("Undo") {}
                ToastView("Wallet disconnected", appearance: .neutral(icon: DesignSystem.Icons.Checkmark.regular20))
                    .closable(false)
                ToastView("Balance is currently hidden", appearance: .info)
                    .action("Unhide") {}
                    .closable(false)
            case .multiline, .multilineLargeText:
                ToastView(Self.longLabel, appearance: .error)
                    .frame(width: 370)
            }
        }
        .padding(16)
    }
}

private extension ToastSnapshotScenario {
    static let longLabel = "WalletConnect couldn't sign the transaction: the dApp sent a request for a network this wallet doesn't support (code 5100). Switch the network in the dApp and try again"
}
