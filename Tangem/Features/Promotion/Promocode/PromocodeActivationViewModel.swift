//
//  PromocodeActivationViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import BlockchainSdk
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
    private let token: PromotionToken
    private let dismissAction: () -> Void

    private var alertOkButton: Alert.Button {
        Alert.Button.default(Text(Localization.commonOk), action: dismissAction)
    }

    // MARK: - Init

    init(promoCode: String, token: PromotionToken, dismissAction: @escaping () -> Void) {
        self.promoCode = promoCode
        self.token = token
        self.dismissAction = dismissAction

        Analytics.log(event: .promotionBannerBannerOpen, params: [.promoCode: promoCode])
    }

    // MARK: - Public Implementation

    func activatePromoCode() async {
        isCheckingPromoCode = true

        defer {
            isCheckingPromoCode = false
        }

        AnalyticsLogger.info("Activating promo code: \(promoCode)")

        // The promo screen is up on the main screen, so the wallets are known: a referral the link brought in
        // before there was one is bound now.
        referralService.retryBindingIfNeeded()

        do {
            // Delay added to handle cold start, since getWalletAddress may fail before wallet models are fully loaded
            try await Task.sleep(for: .seconds(1))
            let (address, userWalletId) = try getWalletInfo()
            let request = makeRequest(address: address, userWalletId: userWalletId)
            logActivationAttempt()
            let response = try await tangemApiService.activatePromoCode(request: request).async()
            logActivationSuccess(campaignId: response.promoProgram?.id)
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
        logActivationFailed(error: error)
        displayErrorAlert(error: error)
    }

    private func getWalletInfo() throws -> (String, UserWalletId) {
        guard let userWalletModel = userWalletRepository.selectedModel else {
            throw PromocodeActivationError.activationError
        }

        var walletModels = AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)

        // Prefer main account's wallet model when multiple accounts are present - this is why we sort them here
        walletModels.sort { first, second in
            let isFirstMainAccount = first.account?.isMainAccount ?? false
            let isSecondMainAccount = second.account?.isMainAccount ?? false
            return isFirstMainAccount && !isSecondMainAccount
        }

        guard let walletModel = walletModels.first(where: { isPayoutTokenItem($0.tokenItem) }) else {
            throw PromocodeActivationError.noAddress(currencyName: currencyName)
        }

        return (walletModel.defaultAddressString, userWalletModel.userWalletId)
    }

    private func isPayoutTokenItem(_ tokenItem: TokenItem) -> Bool {
        guard !tokenItem.blockchain.isTestnet, tokenItem.networkId == networkId else {
            return false
        }

        switch token {
        case .deeplink(_, let currencySymbol):
            return tokenItem.currencySymbol.caseInsensitiveEquals(to: currencySymbol)
        case .bitcoin:
            return true
        }
    }

    private func makeRequest(address: String, userWalletId: UserWalletId) -> PromoCodeActivationDTO.Request {
        switch token {
        case .deeplink(let networkId, let currencySymbol):
            return PromoCodeActivationDTO.Request(
                address: address,
                promoCode: promoCode,
                walletId: userWalletId.stringValue,
                paymentNetwork: networkId,
                paymentCurrency: currencySymbol
            )
        case .bitcoin:
            return PromoCodeActivationDTO.Request(
                address: address,
                promoCode: promoCode,
                walletId: userWalletId.stringValue,
                paymentNetwork: nil,
                paymentCurrency: nil
            )
        }
    }
}

// MARK: - Token

private extension PromocodeActivationViewModel {
    var networkId: String {
        switch token {
        case .deeplink(let networkId, _):
            return networkId
        case .bitcoin:
            return Blockchain.bitcoin(testnet: false).networkId
        }
    }

    var currencySymbol: String {
        switch token {
        case .deeplink(_, let currencySymbol):
            return currencySymbol
        case .bitcoin:
            return Blockchain.bitcoin(testnet: false).currencySymbol
        }
    }

    var blockchain: Blockchain? {
        switch token {
        case .deeplink(let networkId, _):
            return SupportedBlockchains.all.first { $0.networkId == networkId }
        case .bitcoin:
            return .bitcoin(testnet: false)
        }
    }

    var networkName: String {
        blockchain?.displayName ?? networkId
    }

    var currencyName: String {
        guard let blockchain, currencySymbol.caseInsensitiveEquals(to: blockchain.currencySymbol) else {
            return currencySymbol
        }

        return networkName
    }
}

// MARK: - Analytics

private extension PromocodeActivationViewModel {
    var payoutAnalyticsParams: [Analytics.ParameterKey: String] {
        [.promoCode: promoCode, .network: networkId, .token: currencySymbol]
    }

    func logActivationAttempt() {
        let params = payoutAnalyticsParams.merging([.source: "banner"]) { $1 }
        Analytics.log(event: .promotionBannerActivationAttempt, params: params)
    }

    func logActivationSuccess(campaignId: String?) {
        var params = payoutAnalyticsParams
        params[.campaignId] = campaignId
        params[.activationTime] = Date().ISO8601Format()
        Analytics.log(event: .promotionBannerActivationSuccess, params: params)
    }

    func logActivationFailed(error: PromocodeActivationError) {
        let params = payoutAnalyticsParams.merging([.errorCode: error.analyticsErrorCode]) { $1 }
        Analytics.log(event: .promotionBannerActivationFailed, params: params)
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
            message: Text(Localization.promoCodeActivationSuccess(networkName)),
            dismissButton: alertOkButton
        ))
    }
}
