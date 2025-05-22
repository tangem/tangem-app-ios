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
import HotSwiftUI

struct WalletConnectDAppConnectionProposalView: View {
    @ObserveInjection var io
    @ObservedObject var viewModel: WalletConnectDAppConnectionProposalViewModel

    var body: some View {
        contentStateView
            .frame(maxWidth: .infinity)
            .background(Colors.Background.tertiary)
            .floatingSheetContentFrameUpdatePublisher(viewModel.$state)
            .enableInjection()
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
