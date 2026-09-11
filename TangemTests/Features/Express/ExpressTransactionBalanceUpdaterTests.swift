//
//  ExpressTransactionBalanceUpdaterTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import Tangem

@Suite("CommonExpressTransactionBalanceUpdater")
struct ExpressTransactionBalanceUpdaterTests {
    @Test("A done exchange hands the source and destination over to the post-transaction refresh ([REDACTED_INFO])")
    func doneExchangeSchedulesPostTransactionRefresh() async throws {
        let solana = BlockchainNetwork(.solana(curve: .ed25519, testnet: false), derivationPath: nil)
        let sourceItem = TokenItem.blockchain(solana)
        let destinationItem = TokenItem.token(
            .init(name: "Tether", symbol: "USDT", contractAddress: "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB", decimalCount: 6, id: "tether"),
            solana
        )

        let sourceWalletModel = WalletModelTestsMock(tokenItem: sourceItem, isEmpty: false)
        let destinationWalletModel = WalletModelTestsMock(tokenItem: destinationItem, isEmpty: false)
        let userWalletModel = SingleAccountUserWalletModelStub(walletModels: [sourceWalletModel, destinationWalletModel])
        let record = makeRecord(userWalletId: userWalletModel.userWalletId, source: sourceItem, destination: destinationItem)

        try await withInjectedUserWalletRepository(FakeUserWalletRepository(models: [userWalletModel])) {
            let updater = CommonExpressTransactionBalanceUpdater()
            updater.updateBalances(for: [record])

            try await waitUntil {
                sourceWalletModel.updateAfterSendingTransactionCallCount == 1
                    && destinationWalletModel.updateAfterSendingTransactionCallCount == 1
            }

            #expect(sourceWalletModel.updateCallCount == 0, "The updater must not read the balance itself")
            #expect(destinationWalletModel.updateCallCount == 0, "The updater must not read the balance itself")

            #expect(sourceWalletModel.updateAfterSendingTransactionSilentFlags == [true], "The delayed refresh must not flash the loading state")
            #expect(destinationWalletModel.updateAfterSendingTransactionSilentFlags == [true], "The delayed refresh must not flash the loading state")
        }
    }
}

// MARK: - Helpers

private extension ExpressTransactionBalanceUpdaterTests {
    func makeRecord(
        userWalletId: UserWalletId,
        source: TokenItem,
        destination: TokenItem
    ) -> ExpressPendingTransactionRecord {
        ExpressPendingTransactionRecord(
            expressTransactionId: "transaction-id",
            transactionType: .swap,
            transactionHash: "hash",
            expressUserWalletId: userWalletId.stringValue,
            sourceTokenTxInfo: .init(
                userWalletId: userWalletId.stringValue,
                tokenItem: source,
                address: nil,
                amountString: "1",
                isCustom: false
            ),
            destinationTokenTxInfo: .init(
                userWalletId: userWalletId.stringValue,
                tokenItem: destination,
                address: nil,
                amountString: "100",
                isCustom: false
            ),
            feeString: "0.000005",
            provider: .init(id: "provider", name: "Provider", iconURL: nil, type: .dex),
            date: Date(),
            externalTxId: nil,
            externalTxURL: nil,
            averageDuration: nil,
            createdAt: nil,
            isHidden: false,
            transactionStatus: .finished
        )
    }

    func waitUntil(
        pollInterval: Duration = .milliseconds(10),
        maxAttempts: Int = 500,
        condition: () -> Bool
    ) async throws {
        for _ in 0 ..< maxAttempts {
            if condition() {
                return
            }
            try await Task.sleep(for: pollInterval)
        }

        Issue.record("Condition was not met before the timeout")
    }
}

private func withInjectedUserWalletRepository(
    _ repository: UserWalletRepository,
    operation: () async throws -> Void
) async rethrows {
    try await InjectedDependenciesIsolation.shared.run {
        let previous = InjectedValues[\.userWalletRepository]
        InjectedValues[\.userWalletRepository] = repository
        defer { InjectedValues[\.userWalletRepository] = previous }
        try await operation()
    }
}

// MARK: - Stubs

private final class SingleAccountUserWalletModelStub: UserWalletModelMock {
    private let id = UserWalletId(value: Data([0x15, 0x49, 0x5]))
    private let manager: AccountModelsManager

    init(walletModels: [any WalletModel]) {
        let walletModelsManager = WalletModelsManagerTestsMock()
        walletModelsManager.walletModels = walletModels
        manager = AccountModelsManagerStub(
            account: CryptoAccountModelMock(
                isMainAccount: true,
                walletModelsManager: walletModelsManager,
                onArchive: { _ in }
            )
        )
    }

    override var userWalletId: UserWalletId { id }
    override var accountModelsManager: AccountModelsManager { manager }
    override var config: UserWalletConfig { UserWalletConfigStub() }
    override var signer: TangemSigner { TangemSignerStub() }
}
