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
        Analytics.log(.bitcoinPromoDeeplinkActivation)
    }

    // MARK: - Public Implementation

    func activatePromoCode() async {
        isCheckingPromoCode = true

        defer {
            isCheckingPromoCode = false
        }

        do {
            // Delay added to handle cold start, since getWalletAddress may fail before wallet models are fully loaded
            try await Task.sleep(seconds: 1)
            let address = try getWalletAddress()
            let request = PromoCodeActivationDTO.Request(address: address, promoCode: promoCode)
            _ = try await tangemApiService.activatePromoCode(request: request).async()
            Analytics.log(event: .bitcoinPromoActivation, params: [.status: "Activated"])
            displaySuccessAlert()
        } catch let error as TangemAPIError {
            failWith(.init(apiCode: error.code))
        } catch let error as PromocodeActivationError {
            failWith(error)
        } catch {
            failWith(.activationError)
        }
    }

    // MARK: - Private Implementatation

    private func failWith(_ error: PromocodeActivationError) {
        Analytics.log(event: .bitcoinPromoActivation, params: [.status: error.analyticsEventParameter])
        displayErrorAlert(error: error)
    }

    private func getWalletAddress() throws -> String {
        guard let address = userWalletRepository
            .selectedModel?
            .walletModelsManager
            .walletModels
            .first(where: { $0.tokenItem.blockchain == .bitcoin(testnet: false) })?.defaultAddressString
        else {
            throw PromocodeActivationError.noAddress
        }

        return address
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
