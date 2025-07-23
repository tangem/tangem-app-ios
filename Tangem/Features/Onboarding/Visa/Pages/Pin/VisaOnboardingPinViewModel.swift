//
//  OnboardingPinViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
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

    private var shouldSkipValidation = false

    init(delegate: VisaOnboardingPinSelectionDelegate?) {
        self.delegate = delegate

        bind()
    }

    func submitPinCodeAction() {
        Analytics.log(.visaOnboardingButtonSubmitPin)
        isLoading = true
        UIApplication.shared.endEditing()
        let selectedPinCode = pinCode
        runTask(in: self, isDetached: false) { viewModel in
            do {
                try await viewModel.delegate?.useSelectedPin(pinCode: selectedPinCode)
            } catch {
                if !error.isCancellationError {
                    Analytics.log(event: .visaErrors, params: [
                        .errorCode: "\(error.universalErrorCode)",
                        .source: Analytics.ParameterValue.onboarding.rawValue,
                    ])
                    await viewModel.delegate?.showAlertAsync(error.alertBinder)
                }
            }

            await runOnMain {
                viewModel.isLoading = false
            }
        }
    }

    func setupInvalidPinState() {
        shouldSkipValidation = true
        pinCode = ""
        errorMessage = Localization.visaOnboardingPinNotAccepted
        isPinCodeValid = false
    }

    private func bind() {
        $pinCode
            .sink(receiveValue: { [weak self] pin in
                guard let self else { return }

                if shouldSkipValidation {
                    shouldSkipValidation = false
                    return
                }

                do throws(VisaPinValidator.PinValidationError) {
                    try pinValidator.validatePinCode(pin)
                    isPinCodeValid = true
                } catch {
                    errorMessage = error.errorMessage
                    if error.shouldSendAnalyticsEvent {
                        Analytics.log(.visaOnboardingErrorPinValidation)
                    }
                    isPinCodeValid = false
                }
            })
            .store(in: &bag)
    }
}

private extension VisaPinValidator.PinValidationError {
    var errorMessage: String? {
        switch self {
        case .invalidLength: return nil
        case .repeatedDigits, .sequentialDigits:
            return Localization.visaOnboardingPinValidationErrorMessage
        }
    }

    var shouldSendAnalyticsEvent: Bool {
        switch self {
        case .invalidLength: return false
        case .repeatedDigits, .sequentialDigits:
            return true
        }
    }
}
