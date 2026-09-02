//
//  WalletModelFinderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import Testing
@testable import BlockchainSdk
@testable import Tangem

@Suite("WalletModelFinder")
struct WalletModelFinderTests {
    @Test(
        "Each network resolves the wallet on that network, despite the shared address",
        arguments: [
            (Blockchain.ethereum(testnet: false), Constants.ethereumMainnetWalletId),
            (Blockchain.polygon(testnet: false), Constants.polygonMainnetWalletId),
            (Blockchain.ethereum(testnet: true), Constants.ethereumTestnetWalletId),
        ]
    )
    func networkResolvesItsOwnWallet(blockchain: Blockchain, expectedWalletId: UserWalletId) async throws {
        try await Self.withWalletsSharingAddress {
            let result = try WalletModelFinder.findMainWalletModel(
                address: Constants.sharedAddress,
                networkId: blockchain.networkId,
                isTestnet: blockchain.isTestnet
            )

            #expect(result.userWalletModel.userWalletId == expectedWalletId)
            #expect(result.walletModel.tokenItem.networkId == blockchain.networkId)
            #expect(result.walletModel.tokenItem.blockchain.isTestnet == blockchain.isTestnet)
        }
    }

    @Test("Address matching ignores case")
    func addressMatchingIgnoresCase() async throws {
        try await Self.withWalletsSharingAddress {
            let result = try WalletModelFinder.findMainWalletModel(
                address: Constants.sharedAddress.uppercased(),
                networkId: Blockchain.ethereum(testnet: false).networkId,
                isTestnet: false
            )

            #expect(result.userWalletModel.userWalletId == Constants.ethereumMainnetWalletId)
        }
    }

    @Test("An address no wallet holds is not resolved")
    func unknownAddressIsNotResolved() async throws {
        try await Self.withWalletsSharingAddress {
            #expect(throws: WalletModelFinder.Error.self) {
                _ = try WalletModelFinder.findMainWalletModel(
                    address: Constants.unknownAddress,
                    networkId: Blockchain.ethereum(testnet: false).networkId,
                    isTestnet: false
                )
            }
        }
    }
}

// MARK: - Factory methods

private extension WalletModelFinderTests {
    static func withWalletsSharingAddress(_ operation: () async throws -> Void) async throws {
        // Three different networks sharing the same address
        let repository = FakeUserWalletRepository(models: [
            makeUserWalletModel(userWalletId: Constants.ethereumMainnetWalletId, blockchain: .ethereum(testnet: false)),
            makeUserWalletModel(userWalletId: Constants.polygonMainnetWalletId, blockchain: .polygon(testnet: false)),
            makeUserWalletModel(userWalletId: Constants.ethereumTestnetWalletId, blockchain: .ethereum(testnet: true)),
        ])

        try await InjectedDependenciesIsolation.shared.run {
            let previous = InjectedValues[\.userWalletRepository]
            InjectedValues[\.userWalletRepository] = repository
            defer { InjectedValues[\.userWalletRepository] = previous }

            try await operation()
        }
    }

    static func makeUserWalletModel(userWalletId: UserWalletId, blockchain: Blockchain) -> UserWalletModel {
        let walletModel = WalletModelTestsMock(
            tokenItem: .blockchain(.init(blockchain, derivationPath: nil)),
            isEmpty: false,
            addresses: [PlainAddress(value: Constants.sharedAddress, type: .default)]
        )

        let walletModelsManager = WalletModelsManagerTestsMock()
        walletModelsManager.walletModels = [walletModel]

        let account = CryptoAccountModelMock(
            isMainAccount: true,
            walletModelsManager: walletModelsManager,
            onArchive: { _ in }
        )

        return UserWalletModelStub(
            userWalletId: userWalletId,
            accountModelsManager: AccountModelsManagerStub(account: account)
        )
    }
}

// MARK: - Constants

private extension WalletModelFinderTests {
    private enum Constants {
        static let sharedAddress = "0x8fD2a41f1F73C0A26e64d1d5C0e01A66eB7dBA1E"
        static let unknownAddress = "0x0000000000000000000000000000000000000001"

        static let ethereumMainnetWalletId = UserWalletId(value: Data([0x01]))
        static let polygonMainnetWalletId = UserWalletId(value: Data([0x02]))
        static let ethereumTestnetWalletId = UserWalletId(value: Data([0x03]))
    }
}

// MARK: - UserWalletModel stub

private final class UserWalletModelStub: UserWalletModelMock {
    private let id: UserWalletId
    private let manager: AccountModelsManager

    init(userWalletId: UserWalletId, accountModelsManager: AccountModelsManager) {
        id = userWalletId
        manager = accountModelsManager
    }

    override var userWalletId: UserWalletId { id }
    override var accountModelsManager: AccountModelsManager { manager }
}
