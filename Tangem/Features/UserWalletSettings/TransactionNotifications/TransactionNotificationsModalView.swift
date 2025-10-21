//
//  TransactionNotificationsModalView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemAccessibilityIdentifiers

struct TransactionNotificationsModalView: View {
    @ObservedObject var viewModel: TransactionNotificationsModalViewModel

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: Layout.Scroll.spacing) {
                    headerView

                    contentView
                }
                .padding(.horizontal, Layout.Scroll.horizontalPadding)
                .padding(.bottom, Layout.Scroll.bottomPadding)
            }

            overlayButtonView
        }
        .safeAreaInset(edge: .top, spacing: .zero) {
            navigationBarView
        }
        .alert(item: $viewModel.alert, content: { $0.alert })
        .navigationBarTitle("", displayMode: .inline)
        .background(Colors.Background.tertiary.edgesIgnoringSafeArea(.all))
    }

    private var navigationBarView: some View {
        return FloatingSheetNavigationBarView(
            title: "",
            closeButtonAction: viewModel.onGotItTapAction,
            titleAccessibilityIdentifier: WalletConnectAccessibilityIdentifiers.headerTitle
        )
        .padding(.bottom, Layout.NavigationBar.bottomPadding)
    }

    private var headerView: some View {
        VStack(alignment: .center, spacing: Layout.Header.spacing) {
            Assets.pushEligibleNetworks.image
                .frame(size: .init(bothDimensions: 64))

            VStack(alignment: .center, spacing: Layout.Header.textSpacing) {
                Text(Localization.pushTransactionsNotificationsTitle)
                    .style(Fonts.Regular.title1, color: Colors.Text.primary1)
                    .multilineTextAlignment(.center)

                Text(Localization.pushTransactionsNotificationsDescription)
                    .style(Fonts.Regular.subheadline, color: Colors.Text.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: .zero) {
            VStack(alignment: .leading, spacing: .zero) {
                BlockHeaderTitleView(title: Localization.commonSupportedNetworks)
            }

            networkListView
        }
        .roundedBackground(
            with: Colors.Background.action,
            verticalPadding: .zero,
            horizontalPadding: Layout.Content.horizontalPadding,
            radius: Layout.cornerRadius
        )
    }

    private var networkListView: some View {
        VStack(spacing: .zero) {
            ForEach(viewModel.tokenItemViewModels) {
                TransactionNotificationsItemView(viewModel: $0)
            }
        }
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
            .padding(Layout.MainButton.horizontalPadding)
            .padding(Layout.MainButton.bottomPadding)
            .background(LinearGradient(
                colors: [Colors.Background.primary, Colors.Background.primary, Colors.Background.primary.opacity(0)],
                startPoint: .bottom,
                endPoint: .top
            )
            .edgesIgnoringSafeArea(.bottom))
        }
    }
}

extension TransactionNotificationsModalView {
    private enum Layout {
        enum NavigationBar {
            /// 12
            static let bottomPadding: CGFloat = 12
        }

        enum Scroll {
            /// 24
            static let spacing: CGFloat = 24

            /// 16
            static let horizontalPadding: CGFloat = 16

            /// 72
            static let bottomPadding: CGFloat = 96
        }

        enum MainButton {
            /// 16
            static let horizontalPadding: CGFloat = 16

            /// 8
            static let bottomPadding: CGFloat = 8
        }

        enum Content {
            /// 14
            static let horizontalPadding: CGFloat = 14
        }

        enum Header {
            /// 24
            static let spacing: CGFloat = 24

            /// 8
            static let textSpacing: CGFloat = 8
        }

        static let cornerRadius = 14.0
    }
}
