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
    @Published private(set) var errorMessage: String? = nil

    var pinCodeLength: Int {
        pinValidator.pinCodeLength
    }

    var isEnteringPin: Bool {
        state == .enterPin
    }

    var enterPinHeader: String {
        Localization.tangempaySetPinHeader
    }

    private let card: TangemPayCard
    private let tangemPayAccount: TangemPayAccount
    private let userWalletId: UserWalletId
    private weak var coordinator: TangemPayPinRoutable?

    private let pinValidator = VisaPinValidator()
    private var bag = Set<AnyCancellable>()

    init(
        card: TangemPayCard,
        tangemPayAccount: TangemPayAccount,
        userWalletId: UserWalletId,
        coordinator: TangemPayPinRoutable
    ) {
        self.card = card
        self.tangemPayAccount = tangemPayAccount
        self.userWalletId = userWalletId
        self.coordinator = coordinator
        bindRedesigned()
    }

    func onAppear() {
        Analytics.log(.visaScreenChangePinScreenShown, contextParams: .userWallet(userWalletId))
    }

    func close() {
        switch state {
        case .created:
            runTask { [tangemPayAccount] in
                await tangemPayAccount.loadCustomerInfo()
            }

        case .enterPin:
            break
        }
        coordinator?.closeTangemPayPin()
    }

    func submit() {
        submit(pin: pin)
    }

    private func submit(pin: String) {
        Analytics.log(.visaScreenChangePinSubmitClicked, contextParams: .userWallet(userWalletId))

        UIApplication.shared.endEditing()

        isLoading = true

        runTask(in: self) { viewModel in
            do {
                let publicKey = try await RainCryptoUtilities.getRainRSAPublicKey(for: FeatureStorage.instance.visaAPIType)
                let (secretKey, sessionId) = try RainCryptoUtilities.generateSecretKeyAndSessionId(publicKey: publicKey)
                let (encryptedPin, iv) = try RainCryptoUtilities.encryptPin(pin: pin, secretKey: secretKey)

                let response = try await viewModel.card.customerService.setPin(
                    cardId: viewModel.card.cardId,
                    pin: encryptedPin,
                    sessionId: sessionId,
                    iv: iv
                )

                await MainActor.run {
                    viewModel.isLoading = false
                    switch response.result {
                    case .success:
                        Analytics.log(
                            .visaScreenChangePinSuccessShown,
                            contextParams: .userWallet(viewModel.userWalletId)
                        )
                        viewModel.state = .created
                    case .pinTooWeak:
                        viewModel.errorMessage = Localization.visaOnboardingPinValidationErrorMessage
                        viewModel.clearEnteredPin()
                    case .decryptionError, .unknownError, .undefined:
                        viewModel.errorMessage = Localization.tangempayServiceUnavailableTitle
                        viewModel.clearEnteredPin()
                    }
                }
            } catch {
                await MainActor.run {
                    viewModel.errorMessage = Localization.tangempayCardDetailsErrorText
                    viewModel.isLoading = false
                    viewModel.clearEnteredPin()
                }
            }
        }
    }

    private func bindRedesigned() {
        $pin
            .withWeakCaptureOf(self)
            .sink { viewModel, pin in
                viewModel.handleRedesignedPinChange(pin)
            }
            .store(in: &bag)
    }

    private func handleRedesignedPinChange(_ pin: String) {
        guard pin.count == pinCodeLength else {
            if !pin.isEmpty, errorMessage != nil {
                errorMessage = nil
            }
            return
        }

        do throws(VisaPinValidator.PinValidationError) {
            try pinValidator.validatePinCode(pin)
            errorMessage = nil
            submit(pin: pin)
        } catch {
            errorMessage = error.errorMessage ?? Localization.visaOnboardingPinValidationErrorMessage
        }
    }

    private func clearEnteredPin() {
        DispatchQueue.main.async { [weak self] in
            self?.pin = ""
        }
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
