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
                    Text(Localization.commonBalanceTitle)
                        .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                    Spacer()

                    balancePicker
                }

                switch viewModel.state {
                case .common(let commonViewModel):
                    BalancesView(viewModel: commonViewModel)
                case .yield(let yieldViewModel):
                    BalancesView(viewModel: yieldViewModel) {
                        yieldViewModel.showYieldBalanceInfoAction()
                    }
                case .none: EmptyView()
                }
            }

            ScrollableButtonsView(itemsHorizontalOffset: 14, itemsVerticalOffset: 3, buttonsInfo: viewModel.buttons)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Colors.Background.primary)
        .cornerRadiusContinuous(14)
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
