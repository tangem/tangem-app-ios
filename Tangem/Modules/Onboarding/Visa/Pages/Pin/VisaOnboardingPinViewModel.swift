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

protocol VisaOnboardingPinSelectionDelegate: VisaOnboardingAlertPresenter {
    func useSelectedPin(pinCode: String) async throws
}

class VisaOnboardingPinViewModel: ObservableObject {
    @Published var pinCode: String = ""
    @Published var isLoading: Bool = false
    @Published var isPinCodeValid: Bool = false
    @Published var errorMessage: String? = nil

    let pinCodeLength = 4

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

                do throws(PinValidationError) {
                    try validatePinCode(pin)
                    isPinCodeValid = true
                } catch {
                    errorMessage = error.errorMessage
                    isPinCodeValid = false
                }
            })
            .store(in: &bag)
    }

    private func validatePinCode(_ pin: String) throws(PinValidationError) {
        guard pin.count == pinCodeLength else {
            throw .invalidLength
        }

        guard pin.allSatisfy(\.isNumber) else {
            throw .nonNumericCharacters
        }

        let digits = pin.map { $0.wholeNumberValue! }

        if Set(digits).count == 1 {
            throw .repeatedDigits
        }

        let isAscending = zip(digits, digits.dropFirst()).allSatisfy { $1 == $0 + 1 }
        let isDescending = zip(digits, digits.dropFirst()).allSatisfy { $1 == $0 - 1 }

        if isAscending || isDescending {
            throw .sequentialDigits
        }
    }
}

extension VisaOnboardingPinViewModel {
    enum PinValidationError: Error {
        case invalidLength
        case nonNumericCharacters
        case repeatedDigits
        case sequentialDigits

        var errorMessage: String? {
            switch self {
            case .invalidLength: return nil
            case .nonNumericCharacters, .repeatedDigits, .sequentialDigits:
                return Localization.visaOnboardingPinValidationErrorMessage
            }
        }
    }
}
