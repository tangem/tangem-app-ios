//
//  BalanceWithButtonsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import TangemLocalization
import SwiftUI
import TangemAssets
import TangemAccessibilityIdentifiers

struct BalanceWithButtonsView: View {
    @ObservedObject var viewModel: BalanceWithButtonsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    HStack(spacing: 4) {
                        Text(Localization.commonBalanceTitle)
                            .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                        if let apy = viewModel.yieldModuleApy {
                            Text(AppConstants.dotSign)
                                .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                            Text(Localization.yieldModuleTokenDetailsEarnNotificationApy + " " + apy)
                                .style(Fonts.Bold.footnote, color: Colors.Text.accent)
                        }
                    }

                    Spacer()

                    balancePicker
                }

                LoadableTokenBalanceView(
                    state: viewModel.fiatBalance,
                    style: .init(font: Fonts.Regular.title1, textColor: Colors.Text.primary1),
                    loader: .init(
                        size: .init(width: 102, height: 24),
                        padding: .init(top: 5, leading: 0, bottom: 5, trailing: 0),
                        cornerRadius: 6
                    )
                )
                .accessibilityIdentifier(balanceAccessibilityIdentifier(for: viewModel.selectedBalanceType))

                LoadableTokenBalanceView(
                    state: viewModel.cryptoBalance,
                    style: .init(font: Fonts.Regular.footnote, textColor: Colors.Text.tertiary),
                    loader: .init(
                        size: .init(width: 70, height: 12),
                        padding: .init(top: 2, leading: 0, bottom: 2, trailing: 0)
                    )
                )
                .if(viewModel.shouldShowYieldBalanceInfo) {
                    $0.yieldIdentificationIfNeeded {
                        (viewModel.showYieldBalanceInfoAction ?? {})()
                    }
                }
            }

            ScrollableButtonsView(itemsHorizontalOffset: 14, itemsVerticalOffset: 3, buttonsInfo: viewModel.buttons)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(14)
    }

    private func balanceAccessibilityIdentifier(for balanceType: BalanceWithButtonsViewModel.BalanceType) -> String {
        switch balanceType {
        case .all:
            return TokenAccessibilityIdentifiers.totalBalance
        case .available:
            return TokenAccessibilityIdentifiers.availableBalance
        }
    }

    @ViewBuilder
    private var balancePicker: some View {
        if let balanceTypeValues = viewModel.balanceTypeValues {
            SegmentedPicker(
                selectedOption: $viewModel.selectedBalanceType,
                options: balanceTypeValues,
                shouldStretchToFill: false,
                isDisabled: false,
                style: .init(textVerticalPadding: 2)
            ) { $0.title }
        } else {
            EmptyView()
        }
    }
}

struct BalanceWithButtonsView_Previews: PreviewProvider {
    struct BalanceWithButtonsPreview: View {
        private let provider = FakeBalanceWithButtonsInfoProvider()

        var body: some View {
            Group {
                VStack {
                    balanceStateViews(models: provider.models, opacity: 1)
                }
                .padding()
                .frame(maxHeight: .infinity)
                .background(Colors.Background.secondary)
                .previewDisplayName("One by one")

                ZStack {
                    balanceStateViews(models: provider.modelsWithButtons, opacity: 0.1)
                }
                .padding()
                .frame(maxHeight: .infinity)
                .background(Color.black.edgesIgnoringSafeArea(.all))
                .previewDisplayName("Overlaid")
            }
        }

        func balanceStateViews(models: [BalanceWithButtonsViewModel], opacity: Double) -> some View {
            ForEach(models, id: \.id) { model in
                BalanceWithButtonsView(viewModel: model)
                    .opacity(opacity)
            }
        }
    }

    static var previews: some View {
        BalanceWithButtonsPreview()
    }
}
