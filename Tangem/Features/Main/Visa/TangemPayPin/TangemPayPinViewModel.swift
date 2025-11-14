//
//  TangemPayPinViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemVisa
import TangemFoundation
import UIKit
import TangemLocalization

protocol TangemPayPinRoutable: AnyObject {
    func closeTangemPayPin()
}

final class TangemPayPinViewModel: ObservableObject, Identifiable {
    enum State {
        case enterPin
        case created
    }

    let id = UUID()

    @Published private(set) var state: State = .enterPin
    @Published var pin: String = ""
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isPinCodeValid: Bool = false
    @Published private(set) var errorMessage: String? = nil

    var pinCodeLength: Int {
        pinValidator.pinCodeLength
    }

    private let pinValidator = VisaPinValidator()
    private weak var coordinator: TangemPayPinRoutable?
    private var bag = Set<AnyCancellable>()

    init(coordinator: TangemPayPinRoutable) {
        self.coordinator = coordinator
        bind()
    }

    func close() {
        coordinator?.closeTangemPayPin()
    }

    // [REDACTED_TODO_COMMENT]
    // [REDACTED_INFO]
    func submit() {
        isLoading = true
        Task { @MainActor in
            try? await Task.sleep(seconds: 2)
            state = .created
        }
    }

    private func bind() {
        $pin
            .withWeakCaptureOf(self)
            .sink { viewModel, pin in
                do throws(VisaPinValidator.PinValidationError) {
                    try viewModel.pinValidator.validatePinCode(pin)
                    viewModel.isPinCodeValid = true
                    viewModel.errorMessage = nil
                } catch {
                    viewModel.errorMessage = error.errorMessage
                    viewModel.isPinCodeValid = false
                }
            }
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
}
