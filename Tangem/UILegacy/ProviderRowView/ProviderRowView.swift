//
//  ProviderRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI

struct ProviderRowView: View {
    let viewModel: ProviderRowViewModel

    var body: some View {
        if let action = viewModel.tapAction {
            SwiftUI.Button(action: action) { content }
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
        .frame(maxWidth: .infinity)
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
                            color: viewModel.isDisabled ? DesignSystem.Color.textTertiary : DesignSystem.Color.textSecondary
                        )
                }

                Text(viewModel.provider.type)
                    .style(Fonts.Bold.footnote, color: DesignSystem.Color.textPrimary)
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
                        .style(Fonts.Regular.subheadline, color: DesignSystem.Color.textSecondary)
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
                    color: viewModel.isDisabled ? DesignSystem.Color.textTertiary : DesignSystem.Color.textSecondary
                )
                .padding(.vertical, 2)
                .padding(.horizontal, 6)
                .background(DesignSystem.Color.bgPrimary)
                .cornerRadiusContinuous(8)
        case .fcaWarning:
            Text(Localization.expressProviderFcaWarningList)
                .style(
                    Fonts.Bold.caption2,
                    color: viewModel.isDisabled ? DesignSystem.Color.textTertiary : DesignSystem.Color.textSecondary
                )
                .padding(.vertical, 2)
                .padding(.horizontal, 6)
                .background(DesignSystem.Color.bgPrimary)
                .cornerRadiusContinuous(8)
        case .bestRate:
            Text(Localization.expressProviderBestRate)
                .style(Fonts.Bold.caption2, color: DesignSystem.Color.textAccentBlue)
                .accentBadgeStyle()
        case .bestDexRate:
            Text(Localization.expressProviderBestDexRate)
                .style(Fonts.Bold.caption2, color: DesignSystem.Color.textAccentBlue)
                .accentBadgeStyle()
        case .recommended:
            Text(Localization.expressProviderRecommended)
                .style(Fonts.Bold.caption2, color: DesignSystem.Color.textAccentBlue)
                .accentBadgeStyle()
        }
    }

    @ViewBuilder
    private var detailsTypeView: some View {
        switch viewModel.detailsType {
        case .none:
            EmptyView()
        case .selected:
            Assets.check.image
                .renderingMode(.template)
                .foregroundColor(DesignSystem.Color.iconAccentBlue)
        case .chevron:
            Assets.chevron.image
                .renderingMode(.template)
                .foregroundColor(DesignSystem.Color.iconSecondary)
        }
    }
}

#Preview("Light") {
    func viewModel(
        titleFormat: ProviderRowViewModel.TitleFormat,
        badge: ProviderRowViewModel.Badge?,
        isDisabled: Bool = false,
        subtitles: [ProviderRowViewModel.Subtitle] = [],
        detailsType: ProviderRowViewModel.DetailsType? = nil
    ) -> ProviderRowViewModel {
        ProviderRowViewModel(
            provider: .init(
                id: UUID().uuidString,
                iconURL: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/express/1inch_512.png")!,
                name: "1inch",
                type: "DEX"
            ),
            titleFormat: titleFormat,
            isDisabled: isDisabled,
            badge: badge,
            subtitles: [.text("1 132,46 MATIC")] + subtitles,
            detailsType: detailsType
        ) {}
    }

    return GroupedSection([
        viewModel(titleFormat: .prefixAndName, badge: .none, detailsType: .chevron),
        viewModel(titleFormat: .prefixAndName, badge: .bestRate, detailsType: .selected),
        viewModel(
            titleFormat: .name,
            badge: .permissionNeeded,
            subtitles: [.percent("-1.2%", signType: .negative)]
        ),
        viewModel(
            titleFormat: .name,
            badge: .permissionNeeded,
            subtitles: [.percent("0.7%", signType: .positive)]
        ),
        viewModel(titleFormat: .name, badge: .none, isDisabled: true),
        viewModel(titleFormat: .name, badge: .bestRate, isDisabled: true),
        viewModel(titleFormat: .name, badge: .permissionNeeded, isDisabled: true),
    ]) {
        ProviderRowView(viewModel: $0)
    }
    .interItemSpacing(14)
    .innerContentPadding(12)
    .padding()
    .background(DesignSystem.Color.bgPrimary)
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    func viewModel(
        titleFormat: ProviderRowViewModel.TitleFormat,
        badge: ProviderRowViewModel.Badge?,
        isDisabled: Bool = false,
        subtitles: [ProviderRowViewModel.Subtitle] = [],
        detailsType: ProviderRowViewModel.DetailsType? = nil
    ) -> ProviderRowViewModel {
        ProviderRowViewModel(
            provider: .init(
                id: UUID().uuidString,
                iconURL: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/express/1inch_512.png")!,
                name: "1inch",
                type: "DEX"
            ),
            titleFormat: titleFormat,
            isDisabled: isDisabled,
            badge: badge,
            subtitles: [.text("1 132,46 MATIC")] + subtitles,
            detailsType: detailsType
        ) {}
    }

    return GroupedSection([
        viewModel(titleFormat: .prefixAndName, badge: .none, detailsType: .chevron),
        viewModel(titleFormat: .prefixAndName, badge: .bestRate, detailsType: .selected),
        viewModel(
            titleFormat: .name,
            badge: .permissionNeeded,
            subtitles: [.percent("-1.2%", signType: .negative)]
        ),
        viewModel(
            titleFormat: .name,
            badge: .permissionNeeded,
            subtitles: [.percent("0.7%", signType: .positive)]
        ),
        viewModel(titleFormat: .name, badge: .none, isDisabled: true),
        viewModel(titleFormat: .name, badge: .bestRate, isDisabled: true),
        viewModel(titleFormat: .name, badge: .permissionNeeded, isDisabled: true),
    ]) {
        ProviderRowView(viewModel: $0)
    }
    .interItemSpacing(14)
    .innerContentPadding(12)
    .padding()
    .background(DesignSystem.Color.bgPrimary)
    .preferredColorScheme(.dark)
}
