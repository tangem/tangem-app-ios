//
//  ActionMessageShowcase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

#if INTERNAL || DEBUG
import SwiftUI
import TangemAssets
import TangemUI

struct ActionMessageShowcase: View {
    @State private var variant: ActionMessage.Variant = .warning
    @State private var text = "Invite members to join"
    @State private var icon: Icon = .userPlus
    @State private var frameWidth: CGFloat = 346
    @State private var taps = 0

    var body: some View {
        DSShowcase("ActionMessage") { controls in
            controls.picker("Variant", $variant)
            controls.text("Text", $text)
            controls.picker("Icon", $icon)
            controls.value("Frame width", $frameWidth, in: 120 ... 360, step: 1)
            controls.readout("Taps", "\(taps)")
        } stage: {
            ActionMessage(text, icon: icon.image) {
                taps += 1
            }
            .variant(variant)
            .frame(width: frameWidth)
        } matrix: {
            DSShowcaseMatrix(rows: ActionMessage.Variant.allCases, columns: Sample.allCases) { variant, sample in
                ActionMessage(sample.text, icon: DesignSystem.Icons.Info.regular16) {}
                    .variant(variant)
                    .frame(width: 280)
            }
        }
    }
}

private extension ActionMessageShowcase {
    enum Icon: CaseIterable {
        case userPlus
        case walletCheckmark
        case info

        var image: ImageType {
            switch self {
            case .userPlus: DesignSystem.Icons.UserPlus.regular16
            case .walletCheckmark: DesignSystem.Icons.WalletCheckmark.regular16
            case .info: DesignSystem.Icons.Info.regular16
            }
        }
    }

    enum Sample: CaseIterable {
        case short
        case long

        var text: String {
            switch self {
            case .short: "Finish your card backup"
            case .long: "Your card backup is not finished yet. Complete it to protect your funds"
            }
        }
    }
}
#endif
