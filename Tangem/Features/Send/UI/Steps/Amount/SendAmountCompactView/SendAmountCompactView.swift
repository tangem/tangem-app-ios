//
//  SendAmountCompactView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemUIUtils
import TangemAssets
import TangemLocalization
import TangemAccessibilityIdentifiers

struct SendAmountCompactView: View {
    @ObservedObject var viewModel: SendAmountCompactViewModel
    @State private var separatorSize: CGSize = .zero

    private var tappable: Bool = true

    init(viewModel: SendAmountCompactViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: .zero) {
            Button(action: viewModel.userDidTapAmount) {
                SendAmountCompactTokenView(viewModel: viewModel.sendAmountCompactViewModel)
            }
            .allowsHitTesting(tappable)
            .accessibilityIdentifier(SendAccessibilityIdentifiers.fromWalletButton)

            if let receiveTokenViewModel = viewModel.sendReceiveTokenCompactViewModel {
                FixedSpacer(length: 8)

                Button(action: viewModel.userDidTapReceiveTokenAmount) {
                    SendAmountCompactTokenView(viewModel: receiveTokenViewModel)
                }
                .overlay(alignment: .top) {
                    SendAmountCompactViewSeparator(style: viewModel.amountsSeparator)
                        .readGeometry(\.frame.size, bindTo: $separatorSize)
                        .offset(y: -separatorSize.height / 2 - 4) // Half spacer length
                }
                .allowsHitTesting(tappable)
            }

            if let sendSwapProviderCompactViewData = viewModel.sendSwapProviderCompactViewData {
                Separator(color: Colors.Stroke.primary)
                    .padding(.horizontal, 14)

                Button(action: viewModel.userDidTapProvider) {
                    SendSwapProviderCompactView(
                        data: sendSwapProviderCompactViewData,
                        shouldAnimateBestRateBadge: $viewModel.shouldAnimateBestRateBadge
                    )
                }
                .disabled(!sendSwapProviderCompactViewData.isTappable)
                .allowsHitTesting(tappable)
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action, verticalPadding: 0, horizontalPadding: 0)
    }
}

// MARK: - Setupable

extension SendAmountCompactView: Setupable {
    func tappable(_ tappable: Bool) -> Self {
        map { $0.tappable = tappable }
    }
}
