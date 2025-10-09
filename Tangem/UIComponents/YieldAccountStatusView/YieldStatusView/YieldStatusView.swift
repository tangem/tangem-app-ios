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
import TangemAccessibilityIdentifiers

struct YieldStatusView: View {
    @StateObject
    private var viewModel: YieldStatusViewModel

    // MARK: - Init

    init(viewModel: YieldStatusViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Properties

    @State private var rotation = 0.0
    private let animation: Animation = .linear(duration: 1).speed(1).repeatForever(autoreverses: false)

    // MARK: - Dependencies

    private let balanceFormatter = BalanceFormatter()

    // MARK: - View Body

    var body: some View {
        switch viewModel.state {
        case .loading, .closing:
            content
        case .active:
            Button(action: viewModel.onTapAction) {
                content
            }
        }
    }

    // MARK: - Sub Views

    private var content: some View {
        HStack(spacing: .zero) {
            aaveLogo

            VStack(alignment: .leading, spacing: 6) {
                title
                descriptionText
            }

            Spacer()

            trailingView
        }
        .defaultRoundedBackground()
    }

    @ViewBuilder
    private var aaveLogo: some View {
        Assets.YieldModule.yieldModuleAaveLogo.image
            .resizable()
            .scaledToFit()
            .frame(size: .init(bothDimensions: 36))
            .padding(.trailing, 12)
    }

    @ViewBuilder
    private var title: some View {
        switch viewModel.state {
        case .active:
            // [REDACTED_TODO_COMMENT]
            Text("Aave lending is active")
                .style(Fonts.Bold.subheadline, color: Colors.Text.primary1)
        default:
            // [REDACTED_TODO_COMMENT]
            Text("Aave lending")
                .style(Fonts.Bold.subheadline, color: Colors.Text.tertiary)
        }
    }

    @ViewBuilder
    private var descriptionText: some View {
        switch viewModel.state {
        case .loading:
            // [REDACTED_TODO_COMMENT]
            Text("Processing")
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

        case .active:
            // [REDACTED_TODO_COMMENT]
            Text("Interest accrues automatically")
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)

        case .closing:
            // [REDACTED_TODO_COMMENT]
            Text("Stop supplying")
                .style(Fonts.Regular.caption1, color: Colors.Text.tertiary)
        }
    }

    private var loadingIndicator: some View {
        Circle()
            .trim(from: 0.0, to: 0.8)
            .stroke(Colors.Icon.accent, style: StrokeStyle(lineWidth: 2, lineCap: .square))
            .frame(width: 20, height: 20)
            .padding(.horizontal, 2)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(animation) {
                    rotation = 360.0
                }
            }
    }

    private var warning: some View {
        Assets.attention20.image
    }

    private var chevron: some View {
        Assets.chevronRightWithOffset24.image
            .renderingMode(.template)
            .foregroundColor(Colors.Icon.informative)
            .frame(size: .init(bothDimensions: 24))
    }

    @ViewBuilder
    private var trailingView: some View {
        switch viewModel.state {
        case .active(let isApproveNeeded):
            HStack(spacing: 2) {
                if isApproveNeeded {
                    warning
                }

                chevron
            }
        case .loading, .closing:
            loadingIndicator
        }
    }
}
