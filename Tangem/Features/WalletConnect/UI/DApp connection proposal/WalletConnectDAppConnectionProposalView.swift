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
            .floatingSheetContentFrameUpdateTrigger(animationTriggerForState(viewModel.state))
//            .floatingSheetContentFrameUpdateAnimation(for: viewModel.state, animationForState: animationForState)
    }

    @ViewBuilder
    private var contentStateView: some View {
        ZStack {
            switch viewModel.state {
            case .connectionRequest(let viewModel):
                WalletConnectDAppConnectionRequestView(viewModel: viewModel)
                    .transition(.connectionRequest)

            case .verifiedDomain:
                VStack {
                    Button("back") { viewModel.switchToConnectionRequest() }
                }
                .frame(height: 300)
                .background(.yellow)
                .transition(.verifiedDomain)

            case .walletSelector:
                VStack {
                    Button("back") { viewModel.switchToConnectionRequest() }
                }
                .frame(height: 600)
                .background(.orange)
                .transition(.walletSelector)

            case .networkSelector:
                VStack {
                    Button("back") { viewModel.switchToConnectionRequest() }
                }
                .frame(height: 200)
                .background(.red)
                .transition(.networkSelector)
            }
        }
    }

    private func animationForState(_ state: WalletConnectDAppConnectionProposalViewState) -> Animation {
        switch state {
        case .connectionRequest:
            Animation.contentStateSwitch(duration: 0.5, delay: 0)
        case .verifiedDomain:
            Animation.contentStateSwitch(duration: 0.3, delay: 0)
        case .walletSelector:
            Animation.contentStateSwitch(duration: 0.3, delay: 0)
        case .networkSelector:
            Animation.contentStateSwitch(duration: 0.3, delay: 0)
        }

    }

    private func animationTriggerForState(_ state: WalletConnectDAppConnectionProposalViewState) -> Int {
        switch state {
        case .connectionRequest(let viewModel):
            viewModel.animationTrigger
        case .verifiedDomain:
            2
        case .walletSelector:
            3
        case .networkSelector:
            4
        }
    }
}

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

private extension WalletConnectDAppConnectionRequestViewModel {
    @MainActor
    var animationTrigger: Int {
        state.connectionRequestSection.hashValue
    }
}
