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
        YieldAccountBottomSheetContainer(
            title: { title },
            subtitle: { subtitle },
            content: { chart },
            buttonLabel: { Text(Localization.commonGotIt) },
            buttonStyle: TangemButtonStyle(colorStyle: .gray, layout: .flexibleWidth),
            closeAction: { viewModel.closeSheet() },
            buttonAction: { viewModel.closeSheet() }
        )
    }

    // MARK: - Sub Views

    private var title: some View {
        // YIELD [REDACTED_TODO_COMMENT]
        Text("Interest rate is variable")
            .style(Fonts.Bold.title2, color: Colors.Text.primary1)
    }

    private var subtitle: some View {
        VStack(spacing: 16) {
            subtitleTextView
            provider
        }
    }

    private var subtitleTextView: some View {
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
}
