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
import TangemPay

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

    private let tangemPayAccount: TangemPayAccount
    private weak var coordinator: TangemPayPinRoutable?

    private let pinValidator = VisaPinValidator()
    private var bag = Set<AnyCancellable>()

    init(tangemPayAccount: TangemPayAccount, coordinator: TangemPayPinRoutable) {
        self.tangemPayAccount = tangemPayAccount
        self.coordinator = coordinator
        bind()
    }

    func close() {
        switch state {
        case .created:
            tangemPayAccount.loadCustomerInfo()

        case .enterPin:
            break
        }
        coordinator?.closeTangemPayPin()
    }

    func submit() {
        isLoading = true

        runTask(in: self) { [pin] viewModel in
            do {
                let publicKey = try await TangemPayUtilities.getRainRSAPublicKey()
                let (secretKey, sessionId) = try RainCryptoUtilities.generateSecretKeyAndSessionId(publicKey: publicKey)
                let (encryptedPin, iv) = try RainCryptoUtilities.encryptPin(pin: pin, secretKey: secretKey)

                let response = try await viewModel.tangemPayAccount.customerInfoManagementService.setPin(
                    pin: encryptedPin,
                    sessionId: sessionId,
                    iv: iv
                )

                await MainActor.run {
                    viewModel.isLoading = false
                    switch response.result {
                    case .success:
                        viewModel.state = .created
                    case .pinTooWeak:
                        viewModel.errorMessage = Localization.visaOnboardingPinValidationErrorMessage
                    case .decryptionError, .unknownError:
                        viewModel.errorMessage = Localization.tangempayServiceUnavailableTitle
                    }
                }
            } catch {
                await MainActor.run {
                    viewModel.errorMessage = Localization.tangempayCardDetailsErrorText
                    viewModel.isLoading = false
                }
            }
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
