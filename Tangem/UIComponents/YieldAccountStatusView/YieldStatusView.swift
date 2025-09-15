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
        case .processing:
            content
        case .active(_, _, _, let tapAction):
            Button(action: tapAction) {
                content
            }
        }
    }

    // MARK: - Sub Views

    private var content: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                title
                description
            }

            Spacer()

            if case .active(_, _, let isApproveNeeded, _) = status {
                trailingView(isApproveNeeded: isApproveNeeded)
            }
        }
        .defaultRoundedBackground()
    }

    private var title: some View {
        Text(Localization.yieldModuleTokenDetailsEarnNotificationEarningOnYourBalanceTitle)
            .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)
    }

    private var description: some View {
        HStack(spacing: 4) {
            descriptionText

            if case .processing = status {
                loadingIndicator
            }
        }
    }

    private var loadingIndicator: some View {
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

    private var warning: some View {
        Assets.WalletConnect.yellowWarningCircle.image
            .frame(size: .init(bothDimensions: 20))
    }

    private var chevron: some View {
        Assets.chevronRightWithOffset24.image
            .renderingMode(.template)
            .foregroundColor(Colors.Icon.informative)
            .frame(size: .init(bothDimensions: 24))
    }

    @ViewBuilder
    private var descriptionText: some View {
        switch status {
        case .processing:
            Text(Localization.yieldModuleTokenDetailsEarnNotificationProcessing)
                .style(Fonts.Regular.callout, color: Colors.Text.primary1)

        case .active(let income, let annualYield, _, _):
            HStack(spacing: 4) {
                Text(income)
                    .style(Fonts.Regular.callout, color: Colors.Text.primary1)

                Text("•")
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)

                Text(annualYield + "%" + " " + Localization.yieldModuleTokenDetailsEarnNotificationApy)
                    .style(Fonts.Bold.callout, color: Colors.Text.tertiary)
            }
        }
    }

    private func trailingView(isApproveNeeded: Bool) -> some View {
        HStack(spacing: 2) {
            if isApproveNeeded {
                warning
            }

            chevron
        }
    }
}

extension YieldStatusView {
    enum Status {
        case processing
        case active(income: String, annualYield: String, isApproveNeeded: Bool, tapAction: () -> Void)
    }
}
