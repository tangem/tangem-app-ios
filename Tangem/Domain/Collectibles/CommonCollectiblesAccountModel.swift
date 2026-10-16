//
//  CommonCollectiblesAccountModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemCollectibles

/// Presents the manager as an account of the wallet: the manager owns the vault state, this hands it the account
/// identity, name and the balance the app displays, none of which the module knows about.
final class CommonCollectiblesAccountModel {
    let id: CollectiblesAccountId

    private let manager: CollectiblesManager
    private let balanceService: any CollectiblesBalanceService
    private let nameSubject: CurrentValueSubject<String, Never>

    init(manager: CollectiblesManager, name: String, balanceService: any CollectiblesBalanceService) {
        id = CollectiblesAccountId(userWalletId: manager.userWalletId)
        self.manager = manager
        self.balanceService = balanceService
        nameSubject = CurrentValueSubject(name)
    }
}

// MARK: - CollectiblesAccountModel protocol conformance

extension CommonCollectiblesAccountModel: CollectiblesAccountModel {
    var name: String {
        nameSubject.value
    }

    var didChangePublisher: AnyPublisher<Void, Never> {
        nameSubject
            .removeDuplicates()
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    var state: CollectiblesState {
        manager.state
    }

    var statePublisher: AnyPublisher<CollectiblesState, Never> {
        manager.statePublisher
    }

    var hasAccount: Bool {
        manager.hasAccount
    }

    var hasAccountPublisher: AnyPublisher<Bool, Never> {
        manager.hasAccountPublisher
    }

    var fiatTotalTokenBalanceProvider: TokenBalanceProvider {
        balanceService.fiatTotalTokenBalanceProvider
    }

    var usdcTokenBalanceProvider: TokenBalanceProvider {
        balanceService.usdcTokenBalanceProvider
    }

    var vaultUsdcStatePublisher: AnyPublisher<CollectiblesVaultUsdcState, Never> {
        manager.vaultUsdcStatePublisher
    }

    @MainActor
    var purchaseInteractor: any CollectiblesPackPurchaseInteractor {
        let interactor = CollectiblesPackPurchaseInteractorStore.interactor(for: manager.userWalletId) {
            let provider = CommonCollectiblesPurchaseProvider(userWalletID: manager.userWalletId.stringValue)

            return RemoteCollectiblesPackPurchaseInteractor(
                generator: provider,
                signer: manager,
                sentReporter: provider,
                statusProvider: provider,
                opener: provider
            )
        }
        interactor.update(signer: manager)

        return interactor
    }

    func update(name: String) {
        guard name != nameSubject.value else {
            return
        }

        nameSubject.send(name)
    }

    func refreshState() async {
        await manager.refreshState()
    }

    func awaitDeposit() async {
        await manager.awaitDeposit()
    }

    func onboard() async throws {
        try await manager.onboard()
    }
}

// MARK: - CollectiblesPurchaseSigner

extension CollectiblesManager: CollectiblesPurchaseSigner {}
