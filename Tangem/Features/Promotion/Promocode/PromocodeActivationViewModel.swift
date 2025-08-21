//
//  PromocodeActivationViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemLocalization
import struct TangemUIUtils.AlertBinder

@MainActor
final class PromocodeActivationViewModel: ObservableObject {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    @Published var alert: AlertBinder?
    @Published private(set) var isCheckingPromoCode = false

    private let promoCode: String
    private let alertOkButton = Alert.Button.default(Text(Localization.commonOk)) {
        UIApplication.dismissTop(animated: false)
    }

    // MARK: - Init

    init(promoCode: String) {
        self.promoCode = promoCode
    }

    // MARK: - Public Implementation

    func activatePromoCode() async {
        isCheckingPromoCode = true

        defer {
            isCheckingPromoCode = false
        }

        guard let address = getWalletAddress() else {
            displayErrorAlert(error: .noAddress)
            return
        }

        do {
            _ = try await tangemApiService.activatePromoCode(promoCode, walletAddress: address).async()
            displaySuccessAlert()
        } catch {
            handleAPIError(error)
        }
    }

    // MARK: - Private Implementatation
    
    private func handleAPIError(_ error: Error) {
        var promocodeError: PromocodeActivationError

        if let apiError = error as? TangemAPIError {
            switch apiError.code {
            case .badRequest, .forbidden:
                promocodeError = .activationError
            case .notFound:
                promocodeError = .invalidCode
            case .conflict:
                promocodeError = .alreadyActivated
            default:
                promocodeError = .activationError
            }
        } else {
            promocodeError = .activationError
        }

        displayErrorAlert(error: promocodeError)
    }

    private func getWalletAddress() -> String? {
        userWalletRepository
            .selectedModel?
            .walletModelsManager
            .walletModels
            .first(where: { $0.tokenItem.blockchain == .bitcoin(testnet: false) })?.defaultAddressString
    }
}

// MARK: - Alerts

private extension PromocodeActivationViewModel {
    private func displayErrorAlert(error: PromocodeActivationError) {
        alert = AlertBinder(alert: Alert(
            title: Text(error.title),
            message: Text(error.localizedDescription),
            dismissButton: alertOkButton
        ))
    }
    
    private func displaySuccessAlert() {
        alert = AlertBinder(alert: Alert(
            title: Text(Localization.bitcoinPromoActivationSuccessTitle),
            message: Text(Localization.bitcoinPromoActivationSuccess),
            dismissButton: alertOkButton
        ))
    }
}
