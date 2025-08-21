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

    func dismissSelf() {
        UIApplication.dismissTop(animated: false)
    }

    func activatePromoCode() async {
        isCheckingPromoCode = true

        defer {
            isCheckingPromoCode = false
        }

        guard let address = getWalletAddress() else {
            presentAlert(message: "No wallet address")
            return
        }

        do {
            let _ = try await tangemApiService.activatePromoCode(promoCode, walletAddress: address).async()
            presentAlert(message: Localization.bitcoinPromoActivationSuccess)
        } catch let error as TangemAPIError {
            switch error.code {
            case .badRequest:
                presentAlert(message: "400")
            case .forbidden:
                presentAlert(message: "403")
            case .notFound:
                presentAlert(message: "404")
            case .conflict:
                presentAlert(message: "409")
            case .unprocessableEntity:
                presentAlert(message: "422")
            default:
                presentAlert(message: error.localizedDescription)
            }
        } catch {
            presentAlert(message: "Generic Error")
        }
    }

    // MARK: - Private Implementatation

    private func getWalletAddress() -> String? {
        userWalletRepository
            .selectedModel?
            .walletModelsManager
            .walletModels
            .first(where: { $0.tokenItem.blockchain == .bitcoin(testnet: false) })?.defaultAddressString
    }
}


// MARK: - Alerts

extension PromocodeActivationViewModel {
    func createErrorAlert(error: PromocodeActivationError) {
        alert = AlertBinder(alert: Alert(
            title: Text(title),
            message: Text(message),
            dismissButton: alertOkButton
        ))
    }
}
