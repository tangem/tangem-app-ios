//
//  SendCurrencyView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUIUtils
import TangemUI

struct SendCurrencyView: View {
    @ObservedObject private var viewModel: SendCurrencyViewModel
    @State private var isShaking: Bool = false

    private var didTapChangeCurrency: (() -> Void)?

    init(viewModel: SendCurrencyViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ExpressCurrencyView(viewModel: viewModel.expressCurrencyViewModel) {
            SendDecimalNumberTextField(viewModel: viewModel.decimalNumberTextFieldViewModel)
                .minTextScale(SendAmountStep.Constants.amountMinTextScale)
                .alignment(.leading)
                .disabled(viewModel.isInputDisabled)
                .offset(x: isShaking ? 10 : 0)
                .simultaneousGesture(TapGesture().onEnded {
                    viewModel.textFieldDidTapped()
                })
                .onChange(of: viewModel.expressCurrencyViewModel.errorState) { errorState in
                    guard case .insufficientFunds = errorState else {
                        return
                    }

                    isShaking = true
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.2, blendDuration: 0.2)) {
                        isShaking = false
                    }
                }
        }
        .didTapChangeCurrency { didTapChangeCurrency?() }
    }
}

// MARK: - Setupable

extension SendCurrencyView: Setupable {
    func didTapChangeCurrency(_ block: @escaping () -> Void) -> Self {
        map { $0.didTapChangeCurrency = block }
    }
}
