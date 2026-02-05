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
import TangemFoundation
import struct TangemUIUtils.AlertBinder

@MainActor
final class PromocodeActivationViewModel: ObservableObject {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.referralService) private var referralService: ReferralService

    @Published var alert: AlertBinder?
    @Published private(set) var isCheckingPromoCode = false

    private let promoCode: String
    private let refcode: String?
    private let campaign: String?

    private let alertOkButton = Alert.Button.default(Text(Localization.commonOk)) {
        UIApplication.dismissTop(animated: false)
    }

    // MARK: - Init

    init(promoCode: String, refcode: String?, campaign: String?) {
        self.promoCode = promoCode
        self.refcode = refcode
        self.campaign = campaign

        Analytics.log(.bitcoinPromoDeeplinkActivation)
    }

    // MARK: - Public Implementation

    func activatePromoCode() async {
        isCheckingPromoCode = true

        defer {
            isCheckingPromoCode = false
        }

        AnalyticsLogger.debug("Activating promo code: \(promoCode)")

        if let refcode {
            AnalyticsLogger.debug("Refcode was provided: \(refcode)")
            referralService.saveAndBindIfNeeded(refcode: refcode, campaign: campaign)
        }

        do {
            // Delay added to handle cold start, since getWalletAddress may fail before wallet models are fully loaded
            try await Task.sleep(for: .seconds(1))
            let (address, userWalletId) = try getWalletInfo()
            let request = PromoCodeActivationDTO.Request(address: address, promoCode: promoCode, walletId: userWalletId.stringValue)
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

    // MARK: - Private Implementation

    private func failWith(_ error: PromocodeActivationError) {
        Analytics.log(event: .bitcoinPromoActivation, params: [.status: error.analyticsEventParameter])
        displayErrorAlert(error: error)
    }

    private func getWalletInfo() throws -> (String, UserWalletId) {
        guard let userWalletModel = userWalletRepository.selectedModel else {
            throw PromocodeActivationError.noAddress
        }

        var walletModels = AccountsFeatureAwareWalletModelsResolver.walletModels(for: userWalletModel)

        if FeatureProvider.isAvailable(.accounts) {
            // Prefer main account's wallet model when multiple accounts are present - this is why we sort them here
            walletModels.sort { first, second in
                let isFirstMainAccount = first.account?.isMainAccount ?? false
                let isSecondMainAccount = second.account?.isMainAccount ?? false
                return isFirstMainAccount && !isSecondMainAccount
            }
        }

        guard let walletModel = walletModels.first(where: { $0.tokenItem.blockchain == .bitcoin(testnet: false) }) else {
            throw PromocodeActivationError.noAddress
        }

        return (walletModel.defaultAddressString, userWalletModel.userWalletId)
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
