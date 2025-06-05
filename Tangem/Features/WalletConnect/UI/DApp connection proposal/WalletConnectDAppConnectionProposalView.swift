//
//  WalletConnectDAppConnectionProposalView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct WalletConnectDAppConnectionProposalView: View {
    @ObservedObject var viewModel: WalletConnectDAppConnectionProposalViewModel

    var body: some View {
        contentStateView
            .frame(maxWidth: .infinity)
            .background(Colors.Background.tertiary)
    }

    @ViewBuilder
    private var contentStateView: some View {
        ZStack {
            switch viewModel.state {
            case .connectionRequest(let viewModel):
                WalletConnectDAppConnectionRequestView(viewModel: viewModel)
                    .transition(.connectionRequest)

            case .verifiedDomain(let viewModel):
                WalletConnectDAppDomainVerificationView(viewModel: viewModel)
                    .transition(.verifiedDomain)

            case .walletSelector(let viewModel):
                WalletConnectWalletSelectorView(viewModel: viewModel)
                    .transition(.walletSelector)

            case .networkSelector(let viewModel):
                WalletConnectNetworksSelectorView(viewModel: viewModel)
                    .transition(.walletSelector)
            }
        }
    }
}

// [REDACTED_TODO_COMMENT]
private extension Animation {
    static let contentStateSwitch = Self.contentStateSwitch(duration: 0.5, delay: 0)

    static func contentStateSwitch(duration: TimeInterval, delay: TimeInterval) -> Animation {
        Animation.timingCurve(0.69, 0.07, 0.27, 0.95, duration: duration).delay(delay)
    }
}

private extension AnyTransition {
    static let connectionRequest = AnyTransition.asymmetric(
        insertion: .move(edge: .bottom)
            .combined(
                with: .opacity.animation(.contentStateSwitch(duration: 0.3, delay: 0.2))
            ),
        removal: .move(edge: .bottom)
            .combined(
                with: .opacity.animation(.contentStateSwitch(duration: 0.3, delay: 0))
            )
    )

    static let verifiedDomain = Self.connectionRequest

    static let walletSelector = AnyTransition.asymmetric(
        insertion: .move(edge: .top)
            .combined(
                with: .opacity.animation(.contentStateSwitch(duration: 0.3, delay: 0.2))
            ),
        removal: .move(edge: .top)
            .combined(
                with: .opacity.animation(.contentStateSwitch(duration: 0.3, delay: 0))
            )
    )

    static let networkSelector = Self.connectionRequest
}
