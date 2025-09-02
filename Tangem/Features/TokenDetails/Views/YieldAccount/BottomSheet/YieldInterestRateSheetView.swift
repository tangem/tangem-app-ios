//
//  YieldInterestRateSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

@MainActor
final class YieldInterestRateSheetViewModel: ObservableObject, FloatingSheetContentViewModel {
    // MARK: - Injected

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    // MARK: - Properties

    private(set) var lastYearReturns: [String: Double]

    // MARK: - Init

    init(lastYearReturns: [String: Double]) {
        self.lastYearReturns = lastYearReturns
    }

    // MARK: - Public Implementation

    func closeSheet() {
        floatingSheetPresenter.removeActiveSheet()
    }
}

struct YieldInterestRateSheetView: View {
    @ObservedObject var viewModel: YieldInterestRateSheetViewModel

    // MARK: - View Body

    var body: some View {
        VStack(spacing: .zero) {
            toolBar
                .padding(.bottom, 20)

            title
                .padding(.horizontal, 16)
                .padding(.bottom, 6)

            subtitle
                .padding(.horizontal, 16)
                .padding(.bottom, 16)

            provider.padding(.bottom, 32)

            Spacer()

            chart.padding(.bottom, 24)

            gotItButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    // MARK: - Sub Views

    private var toolBar: some View {
        HStack {
            Spacer()
            CircleButton.close(action: viewModel.closeSheet)
        }
    }

    private var title: some View {
        // YIELD [REDACTED_TODO_COMMENT]
        Text("Interest rate is variable")
            .style(Fonts.Bold.title2, color: Colors.Text.primary1)
    }

    private var subtitle: some View {
        // YIELD [REDACTED_TODO_COMMENT]
        Text("Current interest rate is always variable and  automatically computed by AAVE on-chain smart-contract based on real-time supply and demand.")
            .multilineTextAlignment(.center)
            .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
    }

    private var provider: some View {
        HStack(spacing: .zero) {
            // YIELD [REDACTED_TODO_COMMENT]
            Text("Powered by")
                .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                .padding(.trailing, 6)

            Assets.YieldAccount.aaveLogo.image.padding(.trailing, 2)

            // YIELD [REDACTED_TODO_COMMENT]
            Text("AAVE").style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
        }
    }

    private var chart: some View {
        Rectangle()
            .fill(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 200)
    }

    private var gotItButton: some View {
        Button(action: viewModel.closeSheet) {
            Text(Localization.commonGotIt).frame(maxWidth: .infinity)
        }
        .buttonStyle(TangemButtonStyle(colorStyle: .gray))
    }
}
