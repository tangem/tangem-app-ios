//
//  AddressForRewardsSection.swift
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

struct AddressForRewardsSection: View {
    let tokenType: ReferralViewModel.ReadyToBecomeParticipantDisplayMode.TokenType
    let account: ReferralViewModel.SelectedAccountViewData
    let openAccountSelector: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Localization.referralAddressForRewards)
                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
                .padding(.bottom, 8)

            tokenView

            Divider()

            BaseOneLineRowButton(
                icon: nil,
                title: Localization.accountDetailsTitle,
                shouldShowTrailingIcon: true,
                action: openAccountSelector,
                trailingView: {
                    AccountInlineHeaderView(
                        iconData: account.iconViewData,
                        name: account.name
                    )
                    .rowTrailingStyle()
                    .id(account.id)
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

// MARK: - AccountInlineHeaderView+

extension AccountInlineHeaderView {
    func rowTrailingStyle() -> Self {
        iconSettings(.smallSized)
            .nameStyle(Fonts.Regular.body, color: Color.Tangem.Graphic.Neutral.tertiary)
    }
}

#Preview {
    ZStack {
        Color.gray

        AddressForRewardsSection(
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
            ),
            openAccountSelector: {}
        )
    }
}
