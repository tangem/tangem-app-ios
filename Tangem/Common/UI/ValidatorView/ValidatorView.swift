//
//  ValidatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct ValidatorView: SelectableView {
    private let data: ValidatorViewData

    var isSelected: Binding<String>?
    var selectionId: String { data.id }

    init(data: ValidatorViewData) {
        self.data = data
    }

    var body: some View {
        switch data.detailsType {
        case .checkmark:
            Button(action: { isSelectedProxy.wrappedValue.toggle() }) {
                content
            }
        case .none, .chevron, .balance:
            content
        }
    }

    private var content: some View {
        HStack(spacing: .zero) {
            HStack(spacing: 12) {
                image

                info
            }

            if let detailsType = data.detailsType {
                Spacer(minLength: 12)

                detailsView(detailsType: detailsType)
            }
        }
        .padding(.vertical, 12)
    }

    private var image: some View {
        IconView(url: data.imageURL, size: CGSize(width: 36, height: 36))
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(data.name)
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)

            if let aprFormatted = data.aprFormatted {
                HStack(spacing: 4) {
                    Text("APR")
                        .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                    Text(aprFormatted)
                        .style(Fonts.Regular.footnote, color: Colors.Text.accent)
                }
            }
        }
        .lineLimit(1)
    }

    @ViewBuilder
    private func detailsView(detailsType: ValidatorViewData.DetailsType) -> some View {
        switch detailsType {
        case .checkmark:
            CircleCheckmarkIcon(isSelected: isSelectedProxy.wrappedValue)
        case .chevron:
            Assets.chevron.image
        case .balance(let crypto, let fiat):
            VStack(alignment: .trailing, spacing: 2, content: {
                Text(crypto)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)

                Text(fiat)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            })
        }
    }
}

#Preview("SelectableValidatorView") {
    struct StakingValidatorPreview: View {
        @State private var selected: String = ""

        var body: some View {
            ZStack {
                Colors.Background.secondary.ignoresSafeArea()

                SelectableGropedSection([
                    ValidatorViewData(
                        id: UUID().uuidString,
                        name: "InfStones",
                        imageURL: URL(string: "https://assets.stakek.it/validators/infstones.png"),
                        aprFormatted: "0.08%",
                        detailsType: .checkmark
                    ),
                    ValidatorViewData(
                        id: UUID().uuidString,
                        name: "Coinbase",
                        imageURL: URL(string: "https://assets.stakek.it/validators/coinbase.png"),
                        aprFormatted: nil,
                        detailsType: .checkmark
                    ),

                ], selection: $selected) {
                    ValidatorView(data: $0)
                }
                .padding()
            }
        }
    }

    return StakingValidatorPreview()
}

#Preview("ChevronValidatorView") {
    struct StakingValidatorPreview: View {
        @State private var selected: String = ""

        var body: some View {
            ZStack {
                Colors.Background.secondary.ignoresSafeArea()

                GroupedSection([
                    ValidatorViewData(
                        id: UUID().uuidString,
                        name: "InfStones",
                        imageURL: URL(string: "https://assets.stakek.it/validators/infstones.png"),
                        aprFormatted: "0.08%",
                        detailsType: .chevron
                    ),
                    ValidatorViewData(
                        id: UUID().uuidString,
                        name: "Aconcagua",
                        imageURL: URL(string: "https://assets.stakek.it/validators/coinbase.png"),
                        aprFormatted: nil,
                        detailsType: .chevron
                    ),

                ]) {
                    ValidatorView(data: $0)
                }
                .padding()
            }
        }
    }

    return StakingValidatorPreview()
}

#Preview("BalanceValidatorView") {
    struct StakingValidatorPreview: View {
        @State private var selected: String = ""

        var body: some View {
            ZStack {
                Colors.Background.secondary.ignoresSafeArea()

                GroupedSection([
                    ValidatorViewData(
                        id: UUID().uuidString,
                        name: "InfStones",
                        imageURL: URL(string: "https://assets.stakek.it/validators/infstones.png"),
                        aprFormatted: "0.08%",
                        detailsType: .balance(crypto: "543 USD", fiat: "5 SOL")
                    ),
                ]) {
                    ValidatorView(data: $0)
                }
                .padding()
            }
        }
    }

    return StakingValidatorPreview()
}
