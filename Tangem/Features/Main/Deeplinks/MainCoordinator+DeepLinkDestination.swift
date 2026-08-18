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
        case swap(parameters: PredefinedSwapParameters)
        case referral(input: ReferralInputModel)
        case staking(options: StakingDetailsCoordinator.Options)
        case yield(walletModel: any WalletModel, userWalletModel: UserWalletModel)
        case marketsTokenDetails(tokenId: String)
        case tokenExchanges(tokenId: String)
        case externalLink(url: URL)
        case markets(filter: MarketsDeeplinkFilter)
        case onboardVisa(deeplinkString: String?)
        case tangemPayMain(customerWalletId: String, incomingAction: TangemPayIncomingActions?)
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
        case .swap(let parameters):
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
            return deeplinkString.map { "\(rawCaseValue)_\($0)" } ?? rawCaseValue
        case .tangemPayMain(let customerWalletId, let incomingAction):
            return [rawCaseValue, customerWalletId, incomingAction?.rawValue].compactMap { $0 }.joined(separator: "_")
        case .tangemPayTransactionDetails(let payload):
            return "\(rawCaseValue)_\(payload.customerWalletId)_\(payload.deeplinkIdentity)"
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
        case .from(let source, let pair, let extras, _):
            let receiveId = switch pair {
            case .fixed(let receive): WalletModelId(tokenItem: receive.tokenItem).id
            case .deferred: "deferred"
            case .userSelection: "any"
            }
            let amountId = extras?.sourceAmount.map { "\($0)" } ?? "any"
            let providerId = extras?.providerId ?? "any"
            return "from_\(source.userWalletInfo.id.stringValue)_\(source.id.id)_\(receiveId)_\(amountId)_\(providerId)"
        case .to(let receive, _, _):
            return "to_\(receive.userWalletInfo.id.stringValue)_\(receive.id.id)"
        }
    }
}

private extension TangemPayPushPayload {
    var deeplinkIdentity: String {
        switch body {
        case .cardReady, .thresholdTopUp:
            return rawType.rawValue
        case .transactionSpend(let spend),
             .transactionSpendRefund(let spend),
             .declinedTopUp(let spend),
             .declinedReason1(let spend),
             .declinedReason2(let spend),
             .declinedReason3(let spend),
             .declinedReason4(let spend),
             .declinedReason5(let spend),
             .declinedReason6(let spend),
             .declinedReason7(let spend),
             .declinedReason8(let spend),
             .declinedReason9(let spend),
             .declinedReason10(let spend),
             .declinedReason11(let spend),
             .declinedReason12(let spend),
             .declinedReason13(let spend),
             .declinedReason14(let spend),
             .declinedReason15(let spend),
             .declinedReason16(let spend),
             .declinedReason17(let spend):
            return "\(rawType.rawValue)_\(spend.transactionId)"
        case .collateralWithdraw(let collateral), .collateralDeposit(let collateral):
            return "\(rawType.rawValue)_\(collateral.transactionId)"
        }
    }
}
