//
//  WalletConnectDAppConnectionRequestView+NetworksSection.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

import HotSwiftUI

extension WalletConnectDAppConnectionRequestView {
    struct NetworksSection: View {
        let viewModel: WalletConnectDAppConnectionRequestViewState.NetworksSection
        let tapAction: () -> Void

        @ObserveInjection var io

        var body: some View {
            Button(action: tapAction) {
                HStack(spacing: .zero) {
                    viewModel.iconAsset.image
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Colors.Icon.accent)

                    Spacer()
                        .frame(width: 8)

                    Text(viewModel.label)
                        .style(Fonts.Regular.body, color: Colors.Text.primary1)

                    Spacer(minLength: .zero)

                    trailingView

                    viewModel.trailingIconAsset?.image
                        .resizable()
                        .frame(width: 18, height: 24)
                        .foregroundStyle(Colors.Icon.informative)
                }
                .frame(height: 46)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .enableInjection()
        }

        @ViewBuilder
        private var trailingView: some View {
            switch viewModel.state {
            case .loading:
                SkeletonView()
                    .frame(width: 88, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

            case .content(let contentState):
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: 88, height: 24)
            }
        }
    }
}
