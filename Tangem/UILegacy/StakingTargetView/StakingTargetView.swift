//
//  StakingTargetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemUIUtils

struct StakingTargetView: View {
    private let data: StakingTargetViewData
    private let selection: Binding<String>?

    private var namespace: Namespace?

    init(data: StakingTargetViewData, selection: Binding<String>? = nil) {
        self.data = data
        self.selection = selection
    }

    var body: some View {
        switch data.detailsType {
        case .checkmark:
            Button(action: { selection?.isActive(compare: data.address).toggle() }) {
                content
            }
        case .balance(_, .some(let action)):
            Button(action: action) {
                content
            }
        case .none, .balance:
            content
        }
    }

    private var content: some View {
        HStack(spacing: .zero) {
            image

            FixedSpacer(width: 12)

            VStack(alignment: .leading, spacing: 0) {
                topLineView

                bottomLineView
            }

            if let detailsType = data.detailsType {
                Spacer(minLength: 12)

                detailsView(detailsType: detailsType)
            }
        }
        .lineLimit(1)
        .infinityFrame(axis: .horizontal)
        .padding(.vertical, 12)
    }

    private var image: some View {
        IconView(url: data.imageURL, size: CGSize(width: 36, height: 36))
    }

    private var topLineView: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(data.name)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

            if data.isPartner {
                FixedSpacer(width: 6)

                Text(Localization.stakingValidatorsLabel)
                    .style(Fonts.Bold.caption2, color: Colors.Text.constantWhite)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Colors.Text.accent)
                    .cornerRadiusContinuous(6)
            }

            if case .balance(let balance, _) = data.detailsType {
                Spacer(minLength: 4)

                Text(balance.fiat)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
            }
        }
    }

    @ViewBuilder
    private var bottomLineView: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if let subtitle = data.subtitle {
                Text(subtitle)

                if case .balance(let balance, _) = data.detailsType {
                    Spacer(minLength: 4)

                    Text(balance.crypto)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                }
            }
        }
    }

    @ViewBuilder
    private func detailsView(detailsType: StakingTargetViewData.DetailsType) -> some View {
        switch detailsType {
        case .checkmark:
            let isSelected = selection?.isActive(compare: data.address).wrappedValue ?? false
            CheckIconView(isSelected: isSelected)
        default:
            EmptyView()
        }
    }
}

// MARK: - Setupable

extension StakingTargetView: Setupable {
    func geometryEffect(_ namespace: Namespace) -> Self {
        map { $0.namespace = namespace }
    }
}

#Preview("SelectableValidatorView") {
    struct StakingValidatorPreview: View {
        @State private var selected: String = ""

        var body: some View {
            VStack {
                GroupedSection([
                    StakingTargetViewData(
                        address: "1",
                        name: "InfStones",
                        imageURL: URL(string: "https://assets.stakek.it/validators/infstones.png"),
                        subtitleType: .none,
                        detailsType: .checkmark
                    ),
                    StakingTargetViewData(
                        address: "2",
                        name: "Coinbase",
                        imageURL: URL(string: "https://assets.stakek.it/validators/coinbase.png"),
                        subtitleType: .selection(formatted: "0.08%"),
                        detailsType: .checkmark
                    ),
                ]) {
                    StakingTargetView(data: $0, selection: $selected)
                }
                .padding()

                GroupedSection([
                    StakingTargetViewData(
                        address: UUID().uuidString,
                        name: "InfStones",
                        imageURL: URL(string: "https://assets.stakek.it/validators/infstones.png"),
                        subtitleType: .selection(formatted: "0.08%"),
                        detailsType: .balance(.init(crypto: "543 USD", fiat: "5 SOL"), action: nil)
                    ),
                ]) {
                    StakingTargetView(data: $0, selection: $selected)
                }
                .padding()
            }
            .background(Colors.Background.secondary.ignoresSafeArea())
        }
    }

    return StakingValidatorPreview()
}
