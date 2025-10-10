//
//  AddessForRewardsSection.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccounts
import TangemUI
import TangemAssets
import TangemLocalization

struct AddessForRewardsSection: View {
    let tokenType: ReferralViewModel.ReadyToBecomParticipantDisplayMode.TokenType
    let account: ReferralViewModel.SelectedAccountViewData

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Address for rewards")
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                .padding(.bottom, 8)

            tokenView

            Divider()

            BaseOneLineRowButton(
                icon: nil,
                title: "Account",
                shouldShowTrailingIcon: true,
                action: {
                    // Open account selector
                },
                trailingView: {
                    HStack(spacing: 4) {
                        AccountIconView(data: account.iconViewData)
                            .setSettings(.smallSized)

                        Text(account.name)
                            .style(Fonts.Regular.body, color: Colors.Text.tertiary)
                    }
                }
            )
            .padding(.top, 12)
        }
        .roundedBackground(with: Colors.Background.primary, verticalPadding: 12, horizontalPadding: 14)
    }

    @ViewBuilder
    private var tokenView: some View {
        switch tokenType {
        case .token(let tokenIconInfo, let name, let network):
            HStack(spacing: 12) {
                TokenIcon(tokenIconInfo: tokenIconInfo, size: .init(bothDimensions: 36))

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .style(Fonts.Regular.subheadline, color: Colors.Text.primary1)
                    Text(network)
                        .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
                }
            }
            .padding(.vertical, 14)

        case .tokenItem(let tokenItemViewModel):
            ExpressTokenItemView(viewModel: tokenItemViewModel)
        }
    }
}

#Preview {
    ZStack {
        Color.gray

        AddessForRewardsSection(
            tokenType: .token(
                TokenIconInfoBuilder().build(
                    for: .token(value: .cosmosMock),
                    in: .alephium(testnet: false),
                    isCustom: false
                ),
                "Cosmos",
                "Meow"
            ),
            account: ReferralViewModel.SelectedAccountViewData(
                id: "FFF",
                iconViewData: AccountIconView.ViewData(backgroundColor: .red, nameMode: .letter("N")),
                name: "Name"
            )
        )
    }
}
