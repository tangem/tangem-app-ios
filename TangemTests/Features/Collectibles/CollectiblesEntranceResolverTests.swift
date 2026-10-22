//
//  CollectiblesEntranceResolverTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import TangemCollectibles
import TangemFoundation
@testable import Tangem

@Suite("CollectiblesEntranceResolver")
@MainActor
struct CollectiblesEntranceResolverTests {
    typealias SUT = CollectiblesEntranceResolver

    // MARK: - Destination

    @Test("Lets an account holder in whatever the region says", arguments: [true, false])
    func accountHolderGoesToMain(isRegionRestricted: Bool) async {
        let accountModel = CollectiblesAccountModelStub(state: .ready(.stub), hasAccount: true)

        let outcome = await SUT.resolve(for: accountModel, isRegionRestricted: isRegionRestricted)

        #expect(outcome == .open(.main))
    }

    @Test("Takes a newcomer to the welcome screen while the region allows it")
    func newcomerGoesToWelcome() async {
        let outcome = await SUT.resolve(for: nil, isRegionRestricted: false)

        #expect(outcome == .open(.welcome))
    }

    @Test("Stops a newcomer from a restricted region with the sheet")
    func restrictedNewcomerSeesSheet() async {
        let outcome = await SUT.resolve(for: nil, isRegionRestricted: true)

        #expect(outcome == .regionRestricted)
    }

    // MARK: - Reading the state

    @Test("Reads the chain once when this device knows nothing yet")
    func readsUnknownState() async {
        let accountModel = CollectiblesAccountModelStub(state: .unresolved, hasAccount: false)

        _ = await SUT.resolve(for: accountModel, isRegionRestricted: false)

        #expect(accountModel.refreshCount == 1)
    }

    @Test(
        "Leaves a resolved state alone",
        arguments: [CollectiblesState.notOnboarded, .coldOwnerNotDerived]
    )
    func keepsResolvedState(state: CollectiblesState) async {
        let accountModel = CollectiblesAccountModelStub(state: state, hasAccount: false)

        _ = await SUT.resolve(for: accountModel, isRegionRestricted: false)

        #expect(accountModel.refreshCount == 0)
    }
}

// MARK: - Helpers

private final class CollectiblesAccountModelStub: CollectiblesAccountModel {
    let id = CollectiblesAccountId(userWalletId: UserWalletId(value: Data(repeating: 7, count: 32)))
    let name = "Packs account"
    let hasAccount: Bool

    private(set) var state: CollectiblesState
    private(set) var refreshCount = 0

    let fiatTotalTokenBalanceProvider: TokenBalanceProvider = TokenBalanceProviderTestsMock(balance: 0)
    let usdcTokenBalanceProvider: TokenBalanceProvider = TokenBalanceProviderTestsMock(balance: 0)

    init(state: CollectiblesState, hasAccount: Bool) {
        self.state = state
        self.hasAccount = hasAccount
    }

    var didChangePublisher: AnyPublisher<Void, Never> { Empty().eraseToAnyPublisher() }

    var hasAccountPublisher: AnyPublisher<Bool, Never> { Just(hasAccount).eraseToAnyPublisher() }

    func update(name: String) {}

    func onboard() async throws {}

    var vaultUsdcStatePublisher: AnyPublisher<CollectiblesVaultUsdcState, Never> {
        Just(.loading).eraseToAnyPublisher()
    }

    func refreshState() async {
        refreshCount += 1
    }

    func awaitDeposit() async {}

    @MainActor
    var purchaseInteractor: any CollectiblesPackPurchaseInteractor {
        CollectiblesPackPurchaseInteractorStub()
    }

    var buybackInteractor: any CollectiblesBuybackInteractor {
        CollectiblesBuybackInteractorStub()
    }
}

private struct CollectiblesBuybackInteractorStub: CollectiblesBuybackInteractor {
    func sell(nftAddress: String, offer: CollectiblesBuybackOffer) async throws {
        throw CancellationError()
    }
}

@MainActor
private final class CollectiblesPackPurchaseInteractorStub: CollectiblesPackPurchaseInteractor {
    func hasUnfinishedPurchase(machineID: String) -> Bool {
        false
    }

    func purchase(
        machineID: String,
        price: Decimal,
        platformFee: Decimal,
        isTurboModeOn: Bool,
        onStep: @escaping (CollectiblesPackPurchaseStep) -> Void
    ) async throws -> CollectiblesPackPurchaseResult {
        throw CancellationError()
    }
}

private extension CollectiblesVaultInfo {
    static let stub = CollectiblesVaultInfo(
        vaultAddress: "aBRHcE97NY1MjVqGbc2LX2cApfPg9r5h5T1KNZS93oA",
        sessionKey: Data(repeating: 1, count: 32),
        perSpinCap: 300_000_000,
        dailyCap: 1_000_000_000,
        spentToday: 0,
        dayIndex: 20_354
    )
}
