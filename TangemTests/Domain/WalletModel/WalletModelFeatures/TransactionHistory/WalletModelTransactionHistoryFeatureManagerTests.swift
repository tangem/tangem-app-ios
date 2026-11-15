//
//  WalletModelTransactionHistoryFeatureManagerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import BlockchainSdk
import TangemFoundation
@testable import Tangem

@Suite("WalletModelTransactionHistoryFeatureManager", .timeLimit(.minutes(1)))
struct WalletModelTransactionHistoryFeatureManagerTests {
    @Test("A joint account's wallet gets the history provider without swap or onramp")
    func jointAccountWalletGetsProviderWithoutExpress() async {
        let provider = await resolvedProvider(isSafe: true, isJointAccountsAvailable: true)

        #expect(provider != nil)
    }

    @Test("A joint account's wallet gets no history provider while joint accounts are off")
    func jointAccountWalletGetsNoProviderWhileJointAccountsAreOff() async {
        let provider = await resolvedProvider(isSafe: true, isJointAccountsAvailable: false)

        #expect(provider == nil)
    }

    @Test("The wallet's own account gets no history provider without swap or onramp")
    func ownAccountWalletGetsNoProviderWithoutExpress() async {
        let provider = await resolvedProvider(isSafe: false, isJointAccountsAvailable: true)

        #expect(provider == nil)
    }
}

// MARK: - Helpers

private extension WalletModelTransactionHistoryFeatureManagerTests {
    func resolvedProvider(isSafe: Bool, isJointAccountsAvailable: Bool) async -> (any TransactionHistoryProviding)? {
        await InjectedDependenciesIsolation.shared.run {
            let expressAvailabilityProvider = UnsupportedExpressAvailabilityProviderStub()
            let previousProvider = InjectedValues[\.expressAvailabilityProvider]
            InjectedValues[\.expressAvailabilityProvider] = expressAvailabilityProvider
            defer { InjectedValues[\.expressAvailabilityProvider] = previousProvider }

            let sut = WalletModelTransactionHistoryFeatureManager(
                providerResolver: TransactionHistoryProviderResolver(
                    userWalletId: JointAccountCompositionFixture.userWalletId,
                    refcodeProvider: nil,
                    jointAccountsRepository: JointAccountsRepositoryStub(),
                    isJointAccountsAvailable: isJointAccountsAvailable
                ),
                tokenItem: .blockchain(BlockchainNetwork(.base(testnet: false), derivationPath: nil)),
                isSafe: isSafe
            )

            var subscription: AnyCancellable?
            let provider = await withCheckedContinuation { continuation in
                subscription = sut.featurePayloadPublisher
                    .dropFirst()
                    .first()
                    .sink { continuation.resume(returning: $0) }
                expressAvailabilityProvider.availabilityDidChange.send(())
            }
            withExtendedLifetime(subscription) {}

            return provider
        }
    }
}

// MARK: - Stubs

private final class UnsupportedExpressAvailabilityProviderStub: ExpressAvailabilityProvider {
    let availabilityDidChange = PassthroughSubject<Void, Never>()

    var hasCache: Bool { true }
    var availabilityDidChangePublisher: AnyPublisher<Void, Never> { availabilityDidChange.eraseToAnyPublisher() }
    var expressAvailabilityUpdateStateValue: ExpressAvailabilityUpdateState { .updated }
    var expressAvailabilityUpdateState: AnyPublisher<ExpressAvailabilityUpdateState, Never> { Just(.updated).eraseToAnyPublisher() }

    func swapState(for tokenItem: TokenItem) -> TokenItemExpressState { .unavailable }
    func onrampState(for tokenItem: TokenItem) -> TokenItemExpressState { .unavailable }
    func canSwap(tokenItem: TokenItem) -> Bool { false }
    func canOnramp(tokenItem: TokenItem) -> Bool { false }
    func updateExpressAvailability(for items: [TokenItem], forceReload: Bool, userWalletId: String) {}
}
