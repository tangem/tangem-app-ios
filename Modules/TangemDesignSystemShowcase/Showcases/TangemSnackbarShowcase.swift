//
//  TangemSnackbarShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUI

struct TangemSnackbarShowcase: View {
    @State private var showIcon = true
    @State private var showAction = true
    @State private var textLength: TextLength = .short
    @State private var actionCount = 0

    var body: some View {
        DSShowcase("TangemSnackbar") { controls in
            controls.toggle("Icon", $showIcon)
            controls.toggle("Action", $showAction)
            controls.picker("Text length", $textLength)
            controls.readout("Undo taps", "\(actionCount)")
        } stage: {
            snackbar(title: textLength.value, hasIcon: showIcon, hasAction: showAction)
        } matrix: {
            DSShowcaseMatrix(rows: Composition.allCases, columns: TextLength.allCases) { composition, length in
                snackbar(title: length.value, hasIcon: composition.hasIcon, hasAction: composition.hasAction)
                    .frame(width: 320)
            }
        }
    }

    private func snackbar(title: String, hasIcon: Bool, hasAction: Bool) -> TangemSnackbar {
        TangemSnackbar(
            title: title,
            action: hasAction ? TangemSnackbar.Action(title: "Undo", handler: { actionCount += 1 }) : nil
        )
        .icon(hasIcon ? Assets.crossedEyeIcon : nil)
    }
}

private extension TangemSnackbarShowcase {
    enum TextLength: CaseIterable {
        case short
        case medium
        case long

        var value: String {
            switch self {
            case .short: "Balances hidden"
            case .medium: "Balances hidden across all wallets"
            case .long: "Balances are now hidden across all wallets in your Tangem account"
            }
        }
    }

    enum Composition: CaseIterable {
        case iconAndAction
        case action
        case icon
        case plain

        var hasIcon: Bool {
            self == .iconAndAction || self == .icon
        }

        var hasAction: Bool {
            self == .iconAndAction || self == .action
        }
    }
}
#endif
