//
//  TokenAlertReceiveAssetsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemUIUtils

struct TokenAlertReceiveAssetsView: View {
    @ObservedObject var viewModel: TokenAlertReceiveAssetsViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: .zero) {
                mainContent
            }
            .padding(.horizontal, Layout.Content.horizontalPadding)
            .padding(.bottom, Layout.Content.bottomPadding)

            overlayButtonView
        }
        .onAppear(perform: viewModel.onViewAppear)
    }

    @ViewBuilder
    private var mainContent: some View {
        VStack(alignment: .center, spacing: Layout.Content.spacing) {
            TokenIcon(
                tokenIconInfo: viewModel.tokenIconInfo,
                size: IconViewSizeSettings.receiveAlert.iconSize
            )

            VStack(alignment: .center, spacing: Layout.Content.textSpacing) {
                networkTitleView

                descriptionView
            }
        }
        .padding(.top, 12)
    }

    private var networkTitleView: some View {
        VStack(alignment: .center, spacing: .zero) {
            Text(Localization.domainReceiveAssetsOnboardingTitle)
                .style(Fonts.Regular.title3, color: Colors.Text.primary1)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(Localization.domainReceiveAssetsOnboardingNetworkName(viewModel.networkName))
                .style(Fonts.Regular.title3, color: Colors.Text.primary1)
                .multilineTextAlignment(.center)
        }
    }

    private var descriptionView: some View {
        Text(Localization.domainReceiveAssetsOnboardingDescription)
            .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
            .multilineTextAlignment(.center)
    }

    private var overlayButtonView: some View {
        VStack {
            Spacer()

            MainButton(
                title: Localization.commonGotIt,
                style: .secondary,
                isLoading: false,
                isDisabled: false,
                action: viewModel.onGotItTapAction
            )
            .padding(.horizontal, Layout.MainButton.horizontalPadding)
            .padding(.vertical, Layout.MainButton.verticalPadding)
            .background(LinearGradient(
                colors: [Colors.Background.primary, Colors.Background.primary, Colors.Background.primary.opacity(0)],
                startPoint: .bottom,
                endPoint: .top
            )
            .edgesIgnoringSafeArea(.bottom))
        }
    }
}

extension TokenAlertReceiveAssetsView {
    private enum Layout {
        enum Icon {
            static let size: CGFloat = 20
        }

        enum MainButton {
            /// 16
            static let horizontalPadding: CGFloat = 16

            /// 16
            static let verticalPadding: CGFloat = 16
        }

        enum Content {
            /// 24
            static let spacing: CGFloat = 24

            /// 14
            static let horizontalPadding: CGFloat = 32

            /// 12
            static let textSpacing: CGFloat = 12

            /// 114
            static let bottomPadding: CGFloat = 114
        }
    }
}
