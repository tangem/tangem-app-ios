//
//  TangemPayAppleWalletProvisioningInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import PassKit
import TangemFoundation
import TangemLocalization
import TangemPay
import TangemUIUtils
import TangemVisa
import UIKit

final class TangemPayAppleWalletProvisioningInteractor {
    var alertPublisher: AnyPublisher<AlertBinder, Never> {
        alertSubject.eraseToAnyPublisher()
    }

    var refreshPublisher: AnyPublisher<Void, Never> {
        Publishers.Merge3(
            refreshSubject,
            NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification).map { _ in },
            NotificationCenter.default.publisher(for: Notification.Name(PKPassLibraryNotificationName.PKPassLibraryDidChange.rawValue)).map { _ in }
        )
        .prepend(())
        .eraseToAnyPublisher()
    }

    private let userWalletId: UserWalletId
    private let provisioner: TangemPayAppleWalletProvisioner
    private let alertSubject = PassthroughSubject<AlertBinder, Never>()
    private let refreshSubject = PassthroughSubject<Void, Never>()
    private var isInProgress = false

    init(userWalletId: UserWalletId, tokenizationService: TangemPayCardTokenizationService) {
        self.userWalletId = userWalletId
        provisioner = TangemPayAppleWalletProvisioner(tokenizationService: tokenizationService)
    }

    @MainActor
    func isEligible(_ card: TangemPayCard, cardIndex: Int, customerState: VisaCustomerInfoResponse.CustomerState) async -> Bool {
        await provisioner.isEligible(card, cardIndex: cardIndex, customerState: customerState)
    }

    func refresh() {
        refreshSubject.send(())
    }

    func addToWallet(card: TangemPayCard, cardIndex: Int) {
        guard !isInProgress else { return }

        Analytics.log(.visaScreenAddToWalletClicked, contextParams: .userWallet(userWalletId))

        isInProgress = true

        runTask(in: self) { interactor in
            await interactor.performAddToWallet(card: card, cardIndex: cardIndex)
        }
    }
}

private extension TangemPayAppleWalletProvisioningInteractor {
    @MainActor
    func performAddToWallet(card: TangemPayCard, cardIndex: Int) async {
        guard await provisioner.isMissingPass(card: card) else {
            if provisioner.presentPassIfActivationRequired(card: card) {
                VisaLogger.info("Apple Wallet pass for card #\(cardIndex) requires activation, opening it in Wallet")
            } else {
                VisaLogger.info("Apple Wallet pass for card #\(cardIndex) exists on all devices, showing verification alert")
                alertSubject.send(.verificationRequiredAlert)
            }
            isInProgress = false
            return
        }

        VisaLogger.info("Apple Wallet provisioning started for card #\(cardIndex)")

        do {
            let activationState = try await provisioner.addToWallet(card: card)
            VisaLogger.info("Apple Wallet provisioning done for card #\(cardIndex), needs action: \(activationState.requiresUserAction)")
            if activationState.requiresUserAction {
                alertSubject.send(.verificationRequiredAlert)
            }
        } catch {
            handle(error)
        }

        isInProgress = false
        refresh()
    }

    func handle(_ error: TangemPayAppleWalletProvisioningError) {
        if case .passKit(let passKitError) = error, passKitError.isPassKitCancellationError {
            VisaLogger.info("Apple Wallet provisioning cancelled")
            return
        }

        VisaLogger.error("Apple Wallet provisioning failed", error: error)
        alertSubject.send(
            AlertBinder(title: Localization.tangempayAppleWalletAddFailedTitle, message: Localization.tangempayAppleWalletAddFailedMessage)
        )
    }
}

private extension Error {
    var isPassKitCancellationError: Bool {
        let nsError = self as NSError

        return nsError.domain == PKPassKitErrorDomain && PKAddPaymentPassError.cancellationCodes.contains(nsError.code)
    }
}

private extension AlertBinder {
    static var verificationRequiredAlert: AlertBinder {
        AlertBinder(
            title: Localization.tangempayAppleWalletVerificationRequiredTitle,
            message: Localization.tangempayAppleWalletVerificationRequiredMessage
        )
    }
}

private extension PKAddPaymentPassError {
    static var cancellationCodes: Set<Int> {
        [PKAddPaymentPassError.userCancelled.rawValue, PKAddPaymentPassError.systemCancelled.rawValue]
    }
}
