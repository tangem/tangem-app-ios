//
//  TangemPayDepositOwnersPublisherFactoryTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import Tangem

@Suite("TangemPayDepositOwnersPublisherFactory")
struct TangemPayDepositOwnersPublisherFactoryTests {
    @Test("Without Pay accounts the publisher emits an empty list right away, so the history never waits on it")
    func emitsEmptyListWithoutPayAccounts() async throws {
        let userWalletModel = FakeUserWalletModel(
            userWalletName: "Wallet",
            isUserWalletLocked: false,
            isDelayed: false,
            cardsCount: 1,
            userWalletId: UserWalletId(value: Data([1])),
            walletManagers: [],
            config: UserWalletConfigStubs.walletV2Stub
        )
        let repository = FakeUserWalletRepository(models: [userWalletModel])

        let owners = try await TangemPayDepositOwnersPublisherFactory
            .makePublisher(userWalletRepository: repository)
            .first()
            .async()

        #expect(owners.isEmpty)
    }

    @Test("Without wallets the publisher still emits an empty list right away")
    func emitsEmptyListWithoutWallets() async throws {
        let owners = try await TangemPayDepositOwnersPublisherFactory
            .makePublisher(userWalletRepository: FakeUserWalletRepository(models: []))
            .first()
            .async()

        #expect(owners.isEmpty)
    }
}
