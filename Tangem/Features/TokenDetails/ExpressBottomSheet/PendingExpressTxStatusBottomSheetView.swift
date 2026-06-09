//
//  PendingExpressTxStatusBottomSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUIUtils
import TangemUI

struct PendingExpressTxStatusBottomSheetView: View {
    @ObservedObject var viewModel: PendingExpressTxStatusBottomSheetViewModel

    @State private var contentHeight: CGFloat = 0

    /// This animation is created explicitly to synchronise them with the delayed appearance of the notification
    private var animation: Animation {
        .easeInOut(duration: viewModel.animationDuration)
    }

    var body: some View {
        ScrollView {
            content
                .padding(.top, 30)
                .readGeometry(\.size.height) { contentHeight = $0 }
        }
        .background(Colors.Background.tertiary)
        .modifier(ShareButtonModifier(contentHeight: contentHeight, shareAction: viewModel.share))
        .onAppear(perform: viewModel.onAppear)
        // This animations are set explicitly to synchronise them with the delayed appearance of the notification
        .animation(animation, value: viewModel.statusesList)
        .animation(animation, value: viewModel.currentStatusIndex)
        .animation(animation, value: viewModel.notificationViewInputs)
        .animation(animation, value: viewModel.showGoToProviderHeaderButton)
        .bindAlert($viewModel.hideTransactionAlert)
    }

    private var content: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Text(viewModel.sheetTitle)
                    .style(Fonts.Regular.headline, color: Colors.Text.primary1)

                Text(Localization.expressExchangeStatusSubtitle)
                    .style(Fonts.Regular.footnote, color: Colors.Text.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 50)
            .padding(.vertical, 10)

            VStack(spacing: 14) {
                amountsView

                providerView

                viewModel.ratingViewModel.map(RatingView.init)

                statusesView

                ForEach(viewModel.notificationViewInputs) {
                    NotificationView(input: $0)
                        .transition(.bottomNotificationTransition)
                }

                hideTransaction
                    .padding(.top, 10)
            }
            .padding(.vertical, 22)
            .padding(.horizontal, 16)
        }
    }

    private var amountsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 0) {
                Text(Localization.expressEstimatedAmount)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                Spacer(minLength: 8)

                Text(viewModel.timeString)
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
            }

            HStack(spacing: 12) {
                PendingExpressTxTokenInfoView(
                    tokenIconInfo: viewModel.sourceTokenIconInfo,
                    amountText: viewModel.sourceAmountText,
                    fiatAmountTextState: viewModel.sourceFiatAmountTextState
                )

                Assets.arrowRightMini.image
                    .renderingMode(.template)
                    .resizable()
                    .frame(size: .init(bothDimensions: 12))
                    .foregroundColor(Colors.Icon.informative)

                PendingExpressTxTokenInfoView(
                    tokenIconInfo: viewModel.destinationTokenIconInfo,
                    amountText: viewModel.destinationAmountText,
                    fiatAmountTextState: viewModel.destinationFiatAmountTextState
                )
            }
        }
        .defaultRoundedBackground(with: Colors.Background.action)
    }

    private var providerView: some View {
        VStack(spacing: 12) {
            HStack {
                Text(Localization.expressProvider)
                    .style(Fonts.Bold.footnote, color: Colors.Text.tertiary)

                Spacer()

                if let transactionID = viewModel.transactionID {
                    PendingExpressTxIdCopyButtonView(viewModel: .init(transactionID: transactionID))
                }
            }

            ProviderRowView(viewModel: viewModel.providerRowViewModel)
        }
        .defaultRoundedBackground(with: Colors.Background.action)
    }

    private var statusesView: some View {
        PendingExpressTxStatusView(
            title: viewModel.statusViewTitle,
            statusesList: viewModel.statusesList,
            topTrailingAction: viewModel.showGoToProviderHeaderButton ? .goToProvider(action: viewModel.openProviderFromStatusHeader) : .none
        )
        // This prevents notification to appear and disappear on top of the statuses list
        .zIndex(5)
    }
}

// Hide transaction manually

private extension PendingExpressTxStatusBottomSheetView {
    @ViewBuilder
    var hideTransaction: some View {
        if viewModel.isHideButtonShowed {
            Button(
                action: viewModel.showHideTransactionAlert,
                label: {
                    Text(Localization.expressStatusHideButtonText)
                        .style(Fonts.Bold.subheadline, color: Colors.Text.tertiary)
                }
            )
        }
    }
}

// MARK: - Share Button

private struct ShareButtonModifier: ViewModifier {
    let contentHeight: CGFloat
    let shareAction: () -> Void

    private let buttonAreaHeight: CGFloat = MainButton.Size.default.height + 8
    private let dragIndicatorHeight: CGFloat = 20

    private var totalHeight: CGFloat {
        contentHeight + buttonAreaHeight + dragIndicatorHeight
    }

    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .bottom) {
            MainButton(
                title: Localization.commonShare,
                icon: .leading(Assets.share),
                style: .secondary,
                action: shareAction
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .presentationDetents([.height(totalHeight)])
        .presentationDragIndicator(.visible)
    }
}
