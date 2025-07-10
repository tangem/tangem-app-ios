//
//  SendSwapProvidersSelectorProviderView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct SendSwapProvidersSelectorProviderView: SelectableSectionRow {
    let data: SendSwapProvidersSelectorProviderViewData
    @Binding var isSelected: Bool

    var body: some View {
        Button(action: { isSelected = true }) {
            HStack(spacing: 12) {
                IconView(
                    url: data.providerIcon,
                    size: CGSize(width: 36, height: 36),
                    forceKingfisher: true
                )

                VStack(alignment: .leading, spacing: 4) {
                    titleView

                    subtitleView
                }
            }
            .infinityFrame(axis: .horizontal, alignment: .leading)
            .padding(.vertical, 16)
            .padding(.horizontal, 14)
        }
        .disabled(!data.isTappable)
    }

    private var titleView: some View {
        HStack(alignment: .center, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(data.title)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                Text(data.providerType)
                    .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
            }

            badgeView
        }
        .lineLimit(1)
    }

    private var subtitleView: some View {
        HStack(spacing: 4) {
            ForEach(data.subtitles) { subtitle in
                switch subtitle {
                case .text(let text):
                    Text(text)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.tertiary)
                        .multilineTextAlignment(.leading)
                case .percent(let text, let signType):
                    Text(text)
                        .style(Fonts.Regular.subheadline, color: signType.textColor)
                        .multilineTextAlignment(.leading)
                }
            }
        }
    }

    @ViewBuilder
    private var badgeView: some View {
        switch data.badge {
        case .none:
            EmptyView()
        case .permissionNeeded:
            Text(Localization.expressProviderPermissionNeeded)
                .style(Fonts.Bold.caption2, color: Colors.Icon.informative)
                .padding(.vertical, 2)
                .padding(.horizontal, 6)
                .background(Colors.Background.secondary)
                .cornerRadiusContinuous(8)
        case .fcaWarning:
            Text(Localization.expressProviderFcaWarningList)
                .style(Fonts.Bold.caption2, color: Colors.Icon.informative)
                .padding(.vertical, 2)
                .padding(.horizontal, 6)
                .background(Colors.Background.secondary)
                .cornerRadiusContinuous(8)
        case .bestRate:
            Text(Localization.expressProviderBestRate)
                .style(Fonts.Bold.caption2, color: Colors.Icon.accent)
                .padding(.vertical, 2)
                .padding(.horizontal, 6)
                .background(Colors.Icon.accent.opacity(0.1))
                .cornerRadiusContinuous(8)
        }
    }
}
