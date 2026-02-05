//
//  TangemPayAddFundsSheetOptionView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemMacro

struct TangemPayAddFundsSheetOptionView: View {
    let option: Option
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                icon

                titleView
            }
            .infinityFrame(axis: .horizontal, alignment: .leading)
            .padding(.vertical, 14)
        }
    }

    private var icon: some View {
        Colors.Icon.accent.opacity(0.1)
            .frame(width: 36, height: 36)
            .overlay {
                option.icon.image
                    .renderingMode(.template)
                    .foregroundStyle(Colors.Icon.accent)
            }
            .clipShape(Circle())
    }

    private var titleView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(option.title)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

            Text(option.subtitle)
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
        }
        .multilineTextAlignment(.leading)
    }
}

extension TangemPayAddFundsSheetOptionView {
    @RawCaseName
    enum Option: Identifiable {
        case receive
        case swap

        var title: String {
            switch self {
            case .receive: Localization.commonReceive
            case .swap: Localization.commonSwap
            }
        }

        var subtitle: String {
            switch self {
            case .receive: Localization.receiveTokenDescription
            case .swap: Localization.exсhangeTokenDescription
            }
        }

        var icon: ImageType {
            switch self {
            case .receive: Assets.arrowDownMini
            case .swap: Assets.exchangeMini
            }
        }
    }
}
