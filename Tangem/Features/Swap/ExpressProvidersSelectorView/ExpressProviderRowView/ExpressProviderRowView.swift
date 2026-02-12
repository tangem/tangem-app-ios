//
//  ExpressProviderRowView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct ExpressProviderRowView: View {
    let viewModel: ProviderRowViewModel

    var body: some View {
        if let action = viewModel.tapAction {
            Button(action: { action() }) {
                content
            }
            .disabled(viewModel.isDisabled)
        } else {
            content
        }
    }

    private var content: some View {
        HStack(spacing: 12) {
            IconView(url: viewModel.provider.iconURL, size: CGSize(bothDimensions: 36), forceKingfisher: true)
                .saturation(viewModel.isDisabled ? 0 : 1)
                .opacity(viewModel.isDisabled ? 0.4 : 1)
                .padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 4) {
                titleView

                subtitleView
            }

            Spacer()

            detailsTypeView
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .background(backgroundView)
        .overlay { SelectionOverlay().opacity(viewModel.detailsType?.isSelected == true ? 1 : 0) }
        .gesture(DragGesture(minimumDistance: 1))
    }

    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Colors.Background.action)
    }

    private var titleView: some View {
        HStack(alignment: .center, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                switch viewModel.providerTitle {
                case .attributed(let text):
                    Text(text)

                case .text(let text):
                    Text(text)
                        .style(
                            Fonts.Bold.footnote,
                            color: viewModel.isDisabled ? Colors.Text.secondary : Colors.Text.tertiary
                        )
                }

                Text(viewModel.provider.type)
                    .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
            }

            badgeView
        }
        .lineLimit(1)
    }

    private var subtitleView: some View {
        HStack(spacing: 4) {
            ForEach(viewModel.subtitles) { subtitle in
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
        switch viewModel.badge {
        case .none:
            EmptyView()
        case .permissionNeeded:
            Text(Localization.expressProviderPermissionNeeded)
                .style(
                    Fonts.Bold.caption2,
                    color: viewModel.isDisabled ? Colors.Icon.inactive : Colors.Icon.informative
                )
                .padding(.vertical, 2)
                .padding(.horizontal, 6)
                .background(Colors.Background.secondary)
                .cornerRadiusContinuous(8)
        case .fcaWarning:
            Text(Localization.expressProviderFcaWarningList)
                .style(
                    Fonts.Bold.caption2,
                    color: viewModel.isDisabled ? Colors.Icon.inactive : Colors.Icon.informative
                )
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
        case .recommended:
            Text(Localization.expressProviderRecommended)
                .style(Fonts.Bold.caption2, color: Colors.Icon.accent)
                .padding(.vertical, 2)
                .padding(.horizontal, 6)
                .background(Colors.Icon.accent.opacity(0.1))
                .cornerRadiusContinuous(8)
        }
    }

    @ViewBuilder
    private var detailsTypeView: some View {
        if viewModel.detailsType?.isChevron ?? false {
            Assets.chevron.image
                .renderingMode(.template)
                .foregroundColor(Colors.Icon.informative)
        }
    }
}
