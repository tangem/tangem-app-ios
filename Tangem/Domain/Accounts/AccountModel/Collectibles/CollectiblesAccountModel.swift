//
//  CollectiblesAccountModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemCollectibles

protocol CollectiblesBalanceSource: AnyObject {
    var fiatTotalTokenBalanceProvider: TokenBalanceProvider { get }
    var usdcTokenBalanceProvider: TokenBalanceProvider { get }

    func refreshState() async
}

protocol CollectiblesVaultUsdcAccountProvider: AnyObject {
    var vaultUsdcStatePublisher: AnyPublisher<CollectiblesVaultUsdcState, Never> { get }
}

protocol CollectiblesDepositAwaiter: AnyObject {
    func awaitDeposit() async
}

protocol CollectiblesPurchaseSigner: AnyObject {
    var purchaseAddresses: CollectiblesPurchaseAddresses? { get }

    func signPurchase(
        _ purchase: CollectiblesPackPurchase,
        confirmedPrice: CollectiblesConfirmedPrice
    ) async throws -> CollectiblesSignedPurchase

    func sendPurchase(_ signedPurchase: CollectiblesSignedPurchase) async throws(CollectiblesSendError)
}

protocol CollectiblesBuybackSigner: AnyObject {
    var buybackAddresses: CollectiblesBuybackAddresses? { get }

    func signBuyback(
        _ preparedTransaction: Data,
        terms: CollectiblesBuybackTerms
    ) async throws -> CollectiblesSignedBuyback

    func sendBuyback(_ signedBuyback: CollectiblesSignedBuyback) async throws(CollectiblesSendError)
}

protocol CollectiblesPackPurchaseInteractorProvider: AnyObject {
    @MainActor
    var purchaseInteractor: any CollectiblesPackPurchaseInteractor { get }
}

protocol CollectiblesBuybackInteractorProvider: AnyObject {
    var buybackInteractor: any CollectiblesBuybackInteractor { get }
}

/// Refines `CollectiblesOnboarder`: the account model owns the vault's state, so it is also what walks that
/// state to `.ready` — the alternative is a second object deciding the same three questions from its own reads.
protocol CollectiblesAccountModel: BaseAccountModel,
    CollectiblesOnboarder,
    CollectiblesBalanceSource,
    CollectiblesVaultUsdcAccountProvider,
    CollectiblesDepositAwaiter,
    CollectiblesPackPurchaseInteractorProvider,
    CollectiblesBuybackInteractorProvider
    where Icon == AccountModel.StandaloneIcon, ID == CollectiblesAccountId {
    var state: CollectiblesState { get }

    var hasAccount: Bool { get }
    var hasAccountPublisher: AnyPublisher<Bool, Never> { get }

    func update(name: String)
}

// MARK: - Default implementations

extension CollectiblesAccountModel {
    var icon: AccountModel.StandaloneIcon {
        .collectibles
    }

    func analyticsParameters(with builder: any AccountsAnalyticsBuilder) -> [Analytics.ParameterKey: String] {
        [:]
    }

    func resolve<R>(using resolver: R) -> R.Result where R: AccountModelResolving {
        resolver.resolve(accountModel: self)
    }
}
