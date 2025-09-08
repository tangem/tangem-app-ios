//
//  YieldStatusView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI
import TangemAssets

struct YieldStatusView: View {
    
    // MARK: - View State

    let status: Status

    // MARK: - Properties

    @State private var rotation = 0.0
    private let animation: Animation = .linear(duration: 1).speed(1).repeatForever(autoreverses: false)

    // MARK: - View Body

    var body: some View {
        switch status {
        case .processingDeposit:
            content
        case .active(_, _, let tapAction):
            Button(action: tapAction) {
                content
            }
        }
    }

    // MARK: - Sub Views

    @ViewBuilder
    private var content: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                title
                description
            }

            Spacer()

            chevron
        }
        .defaultRoundedBackground()
    }

    @ViewBuilder
    private var title: some View {
        Text(Localization.yieldModuleTokenDetailsEarnNotificationEarningOnYourBalanceTitle)
            .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
    }

    @ViewBuilder
    private var description: some View {
        HStack(spacing: 4) {
            descriptionText
            loadingIndicator
        }
    }

    @ViewBuilder
    private var loadingIndicator: some View {
        if case .processingDeposit = status {
            Circle()
                .trim(from: 0.0, to: 0.8)
                .stroke(Colors.Icon.accent, style: StrokeStyle(lineWidth: 2, lineCap: .square))
                .frame(width: 12, height: 12)
                .padding(.horizontal, 2)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(animation) {
                        rotation = 360.0
                    }
                }
        }
    }

    @ViewBuilder
    private var chevron: some View {
        if case .active = status {
            Assets.chevronRightWithOffset24.image
                .renderingMode(.template)
                .foregroundColor(Colors.Icon.informative)
        }
    }

    @ViewBuilder
    private var descriptionText: some View {
        switch status {
        case .processingDeposit:
            Text(Localization.yieldModuleTokenDetailsEarnNotificationProcessing)
                .style(Fonts.Regular.callout, color: Colors.Text.primary1)

        case .active(let income, let annualYield, _):
            HStack(spacing: 4) {
                Text(income)
                    .style(Fonts.Regular.callout, color: Colors.Text.primary1)

                Text("•")
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                Text(annualYield + "%" + " " + Localization.yieldModuleTokenDetailsEarnNotificationApy)
                    .style(Fonts.Regular.callout, color: Colors.Text.tertiary)
            }
        }
    }
}

extension YieldStatusView {
    enum Status {
        case processingDeposit
        case active(income: String, annualYield: String, tapAction: () -> Void)
    }
}
