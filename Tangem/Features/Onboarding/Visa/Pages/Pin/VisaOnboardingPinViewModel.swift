//
//  OnboardingPinViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit
import TangemFoundation
import TangemVisa

protocol VisaOnboardingPinSelectionDelegate: VisaOnboardingAlertPresenter {
    func useSelectedPin(pinCode: String) async throws
}

class VisaOnboardingPinViewModel: ObservableObject {
    @Published var pinCode: String = ""
    @Published var isLoading: Bool = false
    @Published var isPinCodeValid: Bool = false
    @Published var errorMessage: String? = nil

    var pinCodeLength: Int {
        pinValidator.pinCodeLength
    }

    private let pinValidator = VisaPinValidator()
    private weak var delegate: VisaOnboardingPinSelectionDelegate?
    private var bag = Set<AnyCancellable>()

    init(delegate: VisaOnboardingPinSelectionDelegate?) {
        self.delegate = delegate

        bind()
    }

    func submitPinCodeAction() {
        isLoading = true
        UIApplication.shared.endEditing()
        let selectedPinCode = pinCode
        runTask(in: self, isDetached: false) { viewModel in
            do {
                try await viewModel.delegate?.useSelectedPin(pinCode: selectedPinCode)
            } catch {
                if !error.isCancellationError {
                    await viewModel.delegate?.showAlertAsync(error.universalErrorAlertBinder)
                }
            }

            await runOnMain {
                viewModel.isLoading = false
            }
        }
    }

    private func bind() {
        $pinCode
            .sink(receiveValue: { [weak self] pin in
                guard let self else { return }

                do throws(VisaPinValidator.PinValidationError) {
                    try pinValidator.validatePinCode(pin)
                    isPinCodeValid = true
                } catch {
                    errorMessage = error.errorMessage
                    isPinCodeValid = false
                }
            })
            .store(in: &bag)
    }
}

extension VisaPinValidator.PinValidationError {
    var errorMessage: String? {
        switch self {
        case .invalidLength: return nil
        case .repeatedDigits, .sequentialDigits:
            return Localization.visaOnboardingPinValidationErrorMessage
        }
    }
}
