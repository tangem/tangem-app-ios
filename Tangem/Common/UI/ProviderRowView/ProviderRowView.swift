//
//  ProviderRowView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct ProviderRowViewModel {
    let provider: Provider
    let isDisabled: Bool
    let badge: Badge?
    let subtitles: [Subtitle]
    let detailsType: DetailsType?
    let tapAction: () -> Void
}

extension ProviderRowViewModel: Hashable, Identifiable {
    var id: Int { hashValue }
    static func == (lhs: ProviderRowViewModel, rhs: ProviderRowViewModel) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(provider)
        hasher.combine(isDisabled)
        hasher.combine(badge)
        hasher.combine(subtitles)
        hasher.combine(detailsType)
    }
}

extension ProviderRowViewModel {
    struct Provider: Hashable {
        let iconURL: URL
        let name: String
        let type: String
    }

    enum Badge: String, Hashable {
        case permissionNeeded
        case bestRate
    }

    enum Subtitle: Hashable, Identifiable {
        var id: Int { hashValue }

        case text(String)
        case percent(String, signType: ChangeSignType)
    }

    enum DetailsType: Hashable {
        case selected
        case chevron
    }
}

struct ProviderRowView: View {
    let viewModel: ProviderRowViewModel

    var body: some View {
        Button(action: viewModel.tapAction) {
            content
        }
    }

    private var content: some View {
        HStack(spacing: 12) {
            IconView(url: viewModel.provider.iconURL, size: CGSize(bothDimensions: 36))
                .cornerRadius(0)
                .modifier(if: viewModel.isDisabled) {
                    $0.saturation(0)
                }

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
        HStack(alignment: .bottom, spacing: 4) {
            Text(viewModel.provider.name)
                .style(
                    Fonts.Bold.subheadline,
                    color:
                    viewModel.isDisabled ? Colors.Text.secondary : Colors.Text.primary1
                )

            Text(viewModel.provider.type)
                .style(Fonts.Bold.caption1, color: Colors.Text.tertiary)

            badgeView
        }
        .border(Color.red)
    }

    private var subtitleView: some View {
        HStack(spacing: 4) {
            ForEach(viewModel.subtitles) { subtitle in
                switch subtitle {
                case .text(let text):
                    Text(text)
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                case .percent(let text, let signType):
                    Text(text)
                        .style(Fonts.Regular.footnote, color: signType.textColor)
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
            Text("Permission Needed")
                .style(
                    Fonts.Bold.caption2,
                    color: viewModel.isDisabled ? Colors.Icon.inactive : Colors.Icon.informative
                )
                .padding(.vertical, 2)
                .padding(.horizontal, 6)
                .background(Colors.Background.secondary)
                .cornerRadiusContinuous(8)
        case .bestRate:
            Text("Best Rate")
                .style(Fonts.Bold.caption2, color: Colors.Icon.accent)
                .padding(.vertical, 2)
                .padding(.horizontal, 6)
                .background(Colors.Icon.accent.opacity(0.3))
                .cornerRadiusContinuous(8)
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
                .foregroundColor(Colors.Icon.accent)
        case .chevron:
            Assets.chevron.image
                .renderingMode(.template)
                .foregroundColor(Colors.Icon.informative)
        }
    }
}

struct ProviderRowViewModel_Preview: PreviewProvider {
    static var previews: some View {
        views
            .preferredColorScheme(.light)

        views
            .preferredColorScheme(.dark)
    }

    static var views: some View {
        GroupedSection([
            viewModel(badge: .none, detailsType: .chevron),
            viewModel(badge: .bestRate, detailsType: .selected),
            viewModel(
                badge: .permissionNeeded,
                subtitles: [.percent("-1.2%", signType: .negative)]
            ),
            viewModel(
                badge: .permissionNeeded,
                subtitles: [.percent("0.7%", signType: .positive)]
            ),
            viewModel(badge: .none, isDisabled: true),
            viewModel(badge: .bestRate, isDisabled: true),
            viewModel(badge: .permissionNeeded, isDisabled: true),
        ]) {
            ProviderRowView(viewModel: $0)
        }
        .separatorStyle(.minimum)
        .interItemSpacing(14)
        .interSectionPadding(12)
        .padding()
        .background(Colors.Background.secondary)
    }

    static func viewModel(
        badge: ProviderRowViewModel.Badge?,
        isDisabled: Bool = false,
        subtitles: [ProviderRowViewModel.Subtitle] = [],
        detailsType: ProviderRowViewModel.DetailsType? = nil
    ) -> ProviderRowViewModel {
        ProviderRowViewModel(
            provider: .init(
                iconURL: URL(string: "https://s3.eu-central-1.amazonaws.com/tangem.api/express/1inch_512.png")!,
                name: "1inch",
                type: "DEX"
            ),
            isDisabled: isDisabled,
            badge: badge,
            subtitles: [.text("1 132,46 MATIC")] + subtitles,
            detailsType: detailsType
        ) {}
    }
}
