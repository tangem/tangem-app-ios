//
//  TangemPayIssueAdditionalCardCostPopupView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct TangemPayIssueAdditionalCardCostPopupView: View {
    @ObservedObject var viewModel: TangemPayIssueAdditionalCardCostPopupViewModel

    var body: some View {
        VStack(spacing: 24) {
            iconView
                .padding(.top, 64)

            VStack(spacing: 12) {
                Text(viewModel.title)
                    .style(Fonts.Bold.title3, color: Colors.Text.primary1)
                    .fixedSize(horizontal: false, vertical: true)

                Text(viewModel.description)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)

            VStack(spacing: 12) {
                feeRow

                if viewModel.isInsufficientFunds {
                    insufficientFundsBlock
                }
            }

            MainButton(settings: viewModel.primaryButton)
        }
        .overlay(alignment: .topTrailing) {
            NavigationBarButton
                .close(action: viewModel.dismiss)
                .padding(.top, 8)
        }
        .floatingSheetConfiguration { config in
            config.backgroundInteractionBehavior = .tapToDismiss
        }
        .padding(.bottom, 12)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
    }

    private var iconView: some View {
        Image(systemName: "creditcard.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 28, height: 28)
            .foregroundStyle(Colors.Icon.accent)
            .overlay(alignment: .topTrailing) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Colors.Icon.accent)
                    .background(Colors.Background.primary, in: Circle())
                    .offset(x: 3, y: -3)
            }
            .frame(width: 56, height: 56)
            .background(Colors.Icon.accent.opacity(0.1))
            .clipShape(Circle())
    }

    private var feeRow: some View {
        HStack {
            Text(Localization.tangempayIssueAdditionalCardFeeLabel)
                .style(Fonts.Regular.body, color: Colors.Text.primary1)

            Spacer()

            Text(viewModel.feeText)
                .style(Fonts.Regular.body, color: Colors.Text.tertiary)
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(14)
    }

    private var insufficientFundsBlock: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Assets.Visa.usdc.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 4) {
                    Text(Localization.tangempayIssueAdditionalCardInsufficientFundsTitle)
                        .style(Fonts.Bold.footnote, color: Colors.Text.primary1)

                    Text(Localization.tangempayIssueAdditionalCardInsufficientFundsSubtitle)
                        .style(Fonts.Regular.caption1, color: Colors.Text.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: viewModel.openAddFunds) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Colors.Text.primary1)

                    Text(Localization.tangempayCardDetailsAddFunds)
                        .style(Fonts.Bold.footnote, color: Colors.Text.primary1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Colors.Background.secondary)
                .cornerRadiusContinuous(10)
            }
        }
        .padding(16)
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(14)
    }
}
