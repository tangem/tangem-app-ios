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
    private let backButtonsize: MainButton.Size = .default
    
    var body: some View {
        VStack {
            title

            currentPage

            if viewModel.showNavigationButtons {
                navigationButtons
            }

            Color.clear.frame(height: 1)
        }
        .animation(.easeOut(duration: 0.3), value: viewModel.step)
    }

    @ViewBuilder
    private var title: some View {
        Text(viewModel.title)
            .font(.title2)
            .animation(nil)
    }

    @ViewBuilder
    private var currentPage: some View {
        switch viewModel.step {
        case .amount:
            SendAmountView(namespace: namespace, viewModel: viewModel.sendAmountViewModel)
        case .destination:
            SendDestinationView(namespace: namespace, viewModel: viewModel.sendDestinationViewModel)
        case .fee:
            SendFeeView(namespace: namespace, viewModel: viewModel.sendFeeViewModel)
        case .summary:
            SendSummaryView(namespace: namespace, viewModel: viewModel.sendSummaryViewModel)
        }
    }

    @ViewBuilder
    private var navigationButtons: some View {
        HStack {
            if viewModel.showBackButton {
                SendViewBackButton(
                    backgroundColor: backButtonStyle.background(isDisabled: false),
                    cornerRadius: backButtonStyle.cornerRadius(for: backButtonsize),
                    height: backButtonsize.height,
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
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
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
                )
                .frame(size: CGSize(bothDimensions: height))
        }
    }
}

// MARK: - Preview

struct SendView_Preview: PreviewProvider {
    static let viewModel = SendViewModel(sendType: .send, coordinator: SendRoutableMock())

    static var previews: some View {
        SendView(viewModel: viewModel)
    }
}
