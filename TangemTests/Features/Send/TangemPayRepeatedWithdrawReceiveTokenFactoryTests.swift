//
//  TangemPayRepeatedWithdrawReceiveTokenFactoryTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk
@testable import Tangem

@Suite("Receive token of a repeated Tangem Pay withdrawal")
struct TangemPayRepeatedWithdrawReceiveTokenFactoryTests {
    private let ethereum = TokenItem.blockchain(BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil))

    @Test("A custom token is not repeated, so the receive side is left to the user")
    func customTargetIsNotRepeated() async {
        await withExpress {
            let factory = TangemPayRepeatedWithdrawReceiveTokenFactory(target: makeTarget(walletModel: makeWalletModel(isCustom: true)))

            #expect(factory.makeReceiveToken() == nil)
        }
    }

    @Test("A joint account's token is repeated as a receive-only token")
    func jointTargetIsRepeatedAsReceiveOnly() async throws {
        try await withExpress {
            let factory = TangemPayRepeatedWithdrawReceiveTokenFactory(target: makeTarget(walletModel: makeWalletModel(accountType: .joint)))

            let receiveToken = try #require(factory.makeReceiveToken())
            #expect(receiveToken is SendSourceToken)
            #expect(!(receiveToken is SendSwapableToken))
        }
    }

    @Test("A token waiting for its trustline to load is still repeated")
    func missingTrustlineTargetIsRepeated() async {
        await withExpress {
            let stellar: Blockchain = .stellar(curve: .ed25519, testnet: false)
            let walletModel = makeWalletModel(accountType: .joint)
            walletModel.assetRequirementsManagerMock = AssetRequirementsManagerStub(
                condition: .requiresTrustline(
                    blockchain: stellar,
                    trustlineReserve: Amount(with: stellar, value: 0.5),
                    isProcessing: false
                )
            )

            let factory = TangemPayRepeatedWithdrawReceiveTokenFactory(target: makeTarget(walletModel: walletModel))

            #expect(factory.makeReceiveToken() != nil)
        }
    }

    @Test("An unreachable Express doesn't drop the repeated token")
    func unreachableExpressKeepsTarget() async {
        await withExpress(SwapExpressAvailabilityProviderStub(swapState: .unavailable, updateState: .failed(error: URLError(.notConnectedToInternet)))) {
            let factory = TangemPayRepeatedWithdrawReceiveTokenFactory(target: makeTarget(walletModel: makeWalletModel(accountType: .joint)))

            #expect(factory.makeReceiveToken() != nil)
        }
    }
}

// MARK: - Fixtures

private extension TangemPayRepeatedWithdrawReceiveTokenFactoryTests {
    func makeWalletModel(isCustom: Bool = false, accountType: AccountType = .crypto) -> WalletModelTestsMock {
        WalletModelTestsMock(
            tokenItem: ethereum,
            isEmpty: false,
            fiatBalance: 10,
            account: CryptoAccountModelMock(
                isMainAccount: false,
                accountType: accountType,
                onArchive: { _ in }
            ),
            isCustom: isCustom
        )
    }

    func makeTarget(walletModel: WalletModelTestsMock) -> TangemPayRecentOperationTarget {
        TangemPayRecentOperationTarget(
            paymentAccountTokenItem: ethereum,
            receiveUserWalletInfo: SendSourceTokenStub().userWalletInfo,
            receiveWalletModel: walletModel
        )
    }

    func withExpress<T>(
        _ expressAvailabilityProvider: ExpressAvailabilityProvider = SwapExpressAvailabilityProviderStub(),
        _ body: () async throws -> T
    ) async rethrows -> T {
        try await InjectedDependenciesIsolation.shared.run {
            let previousProvider = InjectedValues[\.expressAvailabilityProvider]
            InjectedValues[\.expressAvailabilityProvider] = expressAvailabilityProvider
            defer { InjectedValues[\.expressAvailabilityProvider] = previousProvider }

            return try await body()
        }
    }
}
