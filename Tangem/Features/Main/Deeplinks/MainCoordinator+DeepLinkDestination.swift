//
//  DeepLinkDestination.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemMacro

extension MainCoordinator {
    @RawCaseName
    enum DeepLinkDestination {
        case expressTransactionStatus(walletModel: any WalletModel, userWalletModel: UserWalletModel, transactionDetails: PendingTransactionDetails)
        case tokenDetails(walletModel: any WalletModel, userWalletModel: UserWalletModel)
        case buy(userWalletModel: UserWalletModel)
        case sell(userWalletModel: UserWalletModel)
        case swapWithDeferredPairResolution(parameters: PredefinedSwapParameters)
        case referral(input: ReferralInputModel)
        case staking(options: StakingDetailsCoordinator.Options)
        case yield(walletModel: any WalletModel, userWalletModel: UserWalletModel)
        case marketsTokenDetails(tokenId: String)
        case tokenExchanges(tokenId: String)
        case externalLink(url: URL)
        case markets(filter: MarketsDeeplinkFilter)
        case onboardVisa(deeplinkString: String)
        case tangemPayMain(customerWalletId: String)
        case tangemPayTransactionDetails(payload: TangemPayPushPayload)
        case newsDetails(newsId: Int)
        case newsList(initialCategoryId: Int?)
        case promo(code: String, refcode: String?, campaign: String?)
        case earn(earnType: EarnFilterType?, networkId: String?)
    }
}

// MARK: - Identifiable

extension MainCoordinator.DeepLinkDestination: Identifiable {
    /// Stable identifier composed from the case name (via `@RawCaseName`) and its associated values,
    /// joined with `_`. Used by `DeeplinkViewPresenterViewModel` to deduplicate presentation requests.
    var id: String {
        switch self {
        case .expressTransactionStatus(_, let userWalletModel, let transactionDetails):
            return "\(rawCaseValue)_\(userWalletModel.userWalletId.stringValue)_\(transactionDetails.id)"
        case .tokenDetails(let walletModel, let userWalletModel):
            return "\(rawCaseValue)_\(userWalletModel.userWalletId.stringValue)_\(walletModel.id.id)"
        case .buy(let userWalletModel):
            return "\(rawCaseValue)_\(userWalletModel.userWalletId.stringValue)"
        case .sell(let userWalletModel):
            return "\(rawCaseValue)_\(userWalletModel.userWalletId.stringValue)"
        case .swapWithDeferredPairResolution(let parameters):
            return "\(rawCaseValue)_\(parameters.deeplinkIdentity)"
        case .referral(let input):
            return "\(rawCaseValue)_\(input.userWalletModel.userWalletId.stringValue)"
        case .staking(let options):
            let sendInput = options.sendInput
            return "\(rawCaseValue)_\(sendInput.userWalletInfo.id.stringValue)_\(sendInput.walletModel.id.id)"
        case .yield(let walletModel, let userWalletModel):
            return "\(rawCaseValue)_\(userWalletModel.userWalletId.stringValue)_\(walletModel.id.id)"
        case .marketsTokenDetails(let tokenId):
            return "\(rawCaseValue)_\(tokenId)"
        case .tokenExchanges(let tokenId):
            return "\(rawCaseValue)_\(tokenId)"
        case .externalLink(let url):
            return "\(rawCaseValue)_\(url.absoluteString)"
        case .markets(let filter):
            return "\(rawCaseValue)_\(filter.order.rawValue)_\(filter.interval.rawValue)"
        case .onboardVisa(let deeplinkString):
            return "\(rawCaseValue)_\(deeplinkString)"
        case .tangemPayMain(let customerWalletId):
            return "\(rawCaseValue)_\(customerWalletId)"
        case .tangemPayTransactionDetails(let payload):
            return "\(rawCaseValue)_\(payload.customerWalletId)_\(payload.body.deeplinkIdentity)"
        case .newsDetails(let newsId):
            return "\(rawCaseValue)_\(newsId)"
        case .newsList(let initialCategoryId):
            return "\(rawCaseValue)_\(initialCategoryId.map(String.init) ?? "all")"
        case .promo(let code, let refcode, let campaign):
            return "\(rawCaseValue)_\(code)_\(refcode ?? "_")_\(campaign ?? "_")"
        case .earn(let earnType, let networkId):
            return "\(rawCaseValue)_\(earnType?.rawValue ?? "all")_\(networkId ?? "any")"
        }
    }
}

// MARK: - Associated value identity helpers

private extension PredefinedSwapParameters {
    var deeplinkIdentity: String {
        switch self {
        case .from(let source, let receive):
            let receiveId = receive.map { WalletModelId(tokenItem: $0.tokenItem).id } ?? "any"
            return "from_\(source.userWalletInfo.id.stringValue)_\(source.id.id)_\(receiveId)"
        case .to(let receive):
            return "to_\(receive.userWalletInfo.id.stringValue)_\(receive.id.id)"
        case .deferredPairResolution(let source, _):
            return "deferred_\(source.userWalletInfo.id.stringValue)_\(source.id.id)"
        }
    }
}

private extension TangemPayPushPayload.Body {
    var deeplinkIdentity: String {
        switch self {
        case .cardReady:
            return "card_ready"
        case .transactionSpend(let spend):
            return "transaction_spend_\(spend.transactionId)"
        case .declinedTopUp(let spend):
            return "declined_top_up_\(spend.transactionId)"
        case .collateralWithdraw(let collateral):
            return "collateral_withdraw_\(collateral.transactionId)"
        case .collateralDeposit(let collateral):
            return "collateral_deposit_\(collateral.transactionId)"
        }
    }
}
