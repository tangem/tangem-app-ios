//
//  PromocodeActivationViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

@MainActor
final class PromocodeActivationViewModel: ObservableObject {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    @Published var isPresentingAlert = false
    @Published private(set) var isCheckingPromoCode = false
    private(set) var alertMessage = ""

    private let promoCode: String

    // MARK: - Init

    init(promoCode: String) {
        self.promoCode = promoCode
    }

    // MARK: - Public Implementation

    func start() async {
        await checkPromoCode()
    }

    func dismissSelf() {
        UIApplication.dismissTop(animated: false)
    }

    // MARK: - Private Implementatation

    private func checkPromoCode() async {
        isCheckingPromoCode = true

        defer {
            isCheckingPromoCode = false
        }

        guard let address = btcAddress() else {
            presentAlert(message: "No BTC address")
            return
        }

        guard let selectedWalletId = userWalletRepository.selectedModel?.userWalletId.stringValue else {
            presentAlert(message: "Generic error")
            return
        }

        do {
            let response = try await tangemApiService.activatePromoCode(promoCode, walletAddress: address).async()
            presentAlert(message: "OK")
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
                presentAlert(message: "Generic Error")
            }
        } catch {
            presentAlert(message: "Generic Error")
        }
    }

    private func btcAddress() -> String? {
        userWalletRepository
            .selectedModel?
            .walletModelsManager
            .walletModels
            .first(where: { $0.tokenItem.blockchain == .bitcoin(testnet: false) })?.defaultAddressString
    }

    private func presentAlert(message: String) {
        alertMessage = message
        isPresentingAlert = true
    }
}
