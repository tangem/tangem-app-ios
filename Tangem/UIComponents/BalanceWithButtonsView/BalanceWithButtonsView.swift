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

// [REDACTED_INFO]: Delete when redesign toggle is removed
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
                style: .init(textVerticalPadding: 2)
            ) { $0.title }
        } else {
            EmptyView()
        }
    }
}

#Preview("One by one") {
    VStack {
        ForEach(FakeBalanceWithButtonsInfoProvider().models, id: \.id) { model in
            BalanceWithButtonsView(viewModel: model)
        }
    }
    .padding()
    .frame(maxHeight: .infinity)
    .background(Colors.Background.secondary)
}

#Preview("Overlaid") {
    ZStack {
        ForEach(FakeBalanceWithButtonsInfoProvider().models, id: \.id) { model in
            BalanceWithButtonsView(viewModel: model)
                .opacity(0.1)
        }
    }
    .padding()
    .frame(maxHeight: .infinity)
    .background(Color.black.edgesIgnoringSafeArea(.all))
}
