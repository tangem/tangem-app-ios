//
//  SendView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct SendView: View {
    @Namespace var namespace

    @ObservedObject var viewModel: SendViewModel

    private let backButtonStyle: MainButton.Style = .secondary
    private let backButtonSize: MainButton.Size = .default
    private let backgroundColor = Colors.Background.tertiary
    private let bottomGradientHeight: CGFloat = 150

    var body: some View {
        VStack {
            header

            ZStack(alignment: .bottom) {
                currentPage
                    .overlay(bottomOverlay(), alignment: .bottom)

                if viewModel.showNavigationButtons {
                    navigationButtons
                }
            }
        }
        .background(backgroundColor.ignoresSafeArea())
        .animation(.easeOut(duration: 0.3), value: viewModel.step)
        .alert(item: $viewModel.alert) { $0.alert }
        .cameraAccessDeniedAlert($viewModel.showCameraDeniedAlert)
    }

    @ViewBuilder
    private var header: some View {
        VStack {
            SheetDragHandler()
                .padding(.bottom, 4)

            if let title = viewModel.title {
                HStack {
                    Color.clear
                        .frame(maxWidth: .infinity, maxHeight: 1)

                    Text(title)
                        .style(Fonts.Bold.body, color: Colors.Text.primary1)
                        .animation(nil)
                        .padding(.vertical, 8)
                        .lineLimit(1)
                        .layoutPriority(1)

                    if viewModel.showQRCodeButton {
                        Button(action: viewModel.scanQRCode) {
                            Assets.qrCode.image
                                .renderingMode(.template)
                                .foregroundColor(Colors.Icon.primary1)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    } else {
                        Color.clear
                            .frame(maxWidth: .infinity, maxHeight: 1)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var currentPage: some View {
        switch viewModel.step {
        case .amount:
            SendAmountView(namespace: namespace, viewModel: viewModel.sendAmountViewModel)
        case .destination:
            SendDestinationView(namespace: namespace, viewModel: viewModel.sendDestinationViewModel)
        case .fee:
            SendFeeView(namespace: namespace, viewModel: viewModel.sendFeeViewModel, bottomSpacing: bottomGradientHeight)
        case .summary:
            SendSummaryView(namespace: namespace, viewModel: viewModel.sendSummaryViewModel)
        case .finish(let sendFinishViewModel):
            SendFinishView(namespace: namespace, viewModel: sendFinishViewModel)
        }
    }

    @ViewBuilder
    private var navigationButtons: some View {
        HStack {
            if viewModel.showBackButton {
                SendViewBackButton(
                    backgroundColor: backButtonStyle.background(isDisabled: false),
                    cornerRadius: backButtonStyle.cornerRadius(for: backButtonSize),
                    height: backButtonSize.height,
                    action: viewModel.back
                )
            }

            if viewModel.showNextButton {
                MainButton(
                    title: Localization.commonNext,
                    style: .primary,
                    size: .default,
                    isDisabled: viewModel.currentStepInvalid,
                    action: viewModel.next
                )
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func bottomOverlay() -> some View {
        if viewModel.showNavigationButtons {
            LinearGradient(colors: [.clear, backgroundColor], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .frame(maxHeight: bottomGradientHeight)
        }
    }
}

// MARK: - Back button

private struct SendViewBackButton: View {
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let height: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            backgroundColor
                .cornerRadiusContinuous(cornerRadius)
                .overlay(
                    Assets.arrowLeftMini
                        .image
                        .renderingMode(.template)
                        .foregroundColor(Colors.Icon.primary1)
                )
                .frame(size: CGSize(bothDimensions: height))
        }
    }
}

// MARK: - Preview

struct SendView_Preview: PreviewProvider {
    static let card = FakeUserWalletModel.wallet3Cards

    static let viewModel = SendViewModel(
        walletName: card.userWalletName,
        walletModel: card.walletModelsManager.walletModels.first!,
        transactionSigner: TransactionSignerMock(),
        sendType: .send,
        emailDataProvider: CardViewModel.mock!,
        coordinator: SendRoutableMock()
    )

    static var previews: some View {
        SendView(viewModel: viewModel)
    }
}
