//
//  CommonTangemPayBalanceServiceTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemFoundation
import TangemPay
@testable import Tangem

@Suite("CommonTangemPayBalanceService networks", .timeLimit(.minutes(1)))
struct CommonTangemPayBalanceServiceTests {
    @Test("Networks reach subscribers as soon as the balance loads")
    func loadedNetworksArePublished() async throws {
        let balance = try makeBalance()
        let sut = makeSUT(balanceResults: [.success(balance)])
        let spy = NetworksSpy(publisher: sut.networksPublisher)

        await sut.loadBalance()

        #expect(spy.values == [[], balance.networks])
        #expect(sut.networks == balance.networks)
    }

    @Test("A late subscriber gets the networks already loaded")
    func lateSubscriberGetsLoadedNetworks() async throws {
        let balance = try makeBalance()
        let sut = makeSUT(balanceResults: [.success(balance)])

        await sut.loadBalance()
        let networks = try await sut.networksPublisher.first().async()

        #expect(networks == balance.networks)
    }

    @Test("A failed reload keeps the networks from the last successful one")
    func failedReloadKeepsNetworks() async throws {
        let balance = try makeBalance()
        let sut = makeSUT(balanceResults: [.success(balance), .failure(.unauthorized)])
        let spy = NetworksSpy(publisher: sut.networksPublisher)

        await sut.loadBalance()
        await sut.loadBalance()

        #expect(spy.values == [[], balance.networks])
        #expect(sut.networks == balance.networks)
    }

    @Test("Reloading the same networks does not emit them again")
    func unchangedNetworksAreNotRepublished() async throws {
        let balance = try makeBalance()
        let sut = makeSUT(balanceResults: [.success(balance), .success(balance)])
        let spy = NetworksSpy(publisher: sut.networksPublisher)

        await sut.loadBalance()
        await sut.loadBalance()

        #expect(spy.values == [[], balance.networks])
    }

    @Test("Changed networks are published on reload")
    func changedNetworksArePublished() async throws {
        let first = try makeBalance()
        let second = try makeBalance(depositAddress: "0xanother")
        let sut = makeSUT(balanceResults: [.success(first), .success(second)])
        let spy = NetworksSpy(publisher: sut.networksPublisher)

        await sut.loadBalance()
        await sut.loadBalance()

        #expect(spy.values == [[], first.networks, second.networks])
    }
}

// MARK: - Helpers

private extension CommonTangemPayBalanceServiceTests {
    func makeSUT(balanceResults: [Result<TangemPayBalance, TangemPayAPIServiceError>]) -> CommonTangemPayBalanceService {
        CommonTangemPayBalanceService(
            customerInfoManagementService: CustomerInfoManagementServiceStub(balanceResults: balanceResults),
            tokenBalancesRepository: TokenBalancesRepositoryStub(),
            fiatRateProvider: FiatRateProviderStub()
        )
    }

    func makeBalance(depositAddress: String = "0xdeposit") throws -> TangemPayBalance {
        try makeTangemPayBalance(
            networks: """
            [
              {
                "name": "polygon-pos",
                "isTestnet": false,
                "chainId": 137,
                "status": "ENABLED",
                "depositAddress": "\(depositAddress)",
                "tokens": [
                  { "token": "USDC", "tokenContractAddress": "0xusdc", "availableForWithdrawal": 12.5 }
                ]
              }
            ]
            """
        )
    }
}

// MARK: - Stubs

private final class NetworksSpy {
    private let state = OSAllocatedUnfairLock(initialState: [[TangemPayBalance.Network]]())
    private var cancellable: AnyCancellable?

    var values: [[TangemPayBalance.Network]] {
        state.withLock { $0 }
    }

    init(publisher: some Publisher<[TangemPayBalance.Network], Never>) {
        cancellable = publisher.sink { [state] networks in
            state.withLock { $0.append(networks) }
        }
    }
}

private final class FiatRateProviderStub: FiatRateProvider {
    let rate: WalletModelRate = .custom

    var ratePublisher: AnyPublisher<WalletModelRate, Never> {
        Just(rate).eraseToAnyPublisher()
    }

    func updateRate() {}
}

private final class TokenBalancesRepositoryStub: TokenBalancesRepository {
    func balance(walletModelId: WalletModelId, type: CachedBalanceType) -> CachedBalance? {
        nil
    }

    func store(balance: CachedBalance, for walletModelId: WalletModelId, type: CachedBalanceType) {}
}
