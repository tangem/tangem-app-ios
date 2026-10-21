//
//  TokenAdderTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import Tangem

@Suite("TokenAdder")
struct TokenAdderTests {
    @Test("The token goes to the requested wallet even when an earlier wallet has the same network")
    func addsTokenToRequestedWallet() async throws {
        let ethereum = BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil)
        let usdt = TokenItem.token(
            .init(name: "Tether", symbol: "USDT", contractAddress: "0xdAC17F958D2ee523a2206206994597C13D831ec7", decimalCount: 6, id: "tether"),
            ethereum
        )

        var addedToOtherWallet: [TokenItem] = []
        var addedToSourceWallet: [TokenItem] = []
        let otherWallet = makeUserWallet(seed: "other", network: ethereum) { addedToOtherWallet += $0 }
        let sourceWallet = makeUserWallet(seed: "source", network: ethereum) { addedToSourceWallet += $0 }

        try await InjectedDependenciesIsolation.shared.run {
            let previous = InjectedValues[\.userWalletRepository]
            InjectedValues[\.userWalletRepository] = FakeUserWalletRepository(models: [otherWallet, sourceWallet])
            defer { InjectedValues[\.userWalletRepository] = previous }

            try TokenAdder.addToken(tokenItem: usdt, userWalletId: sourceWallet.userWalletId)
        }

        #expect(addedToSourceWallet == [usdt])
        #expect(addedToOtherWallet.isEmpty)
    }
}

// MARK: - Helpers

private extension TokenAdderTests {
    func makeUserWallet(
        seed: String,
        network: BlockchainNetwork,
        onUpdate: @escaping ([TokenItem]) -> Void
    ) -> UserWalletModel {
        let userTokensManager = UserTokensManagerMock(onUpdate: onUpdate)
        let walletModelsManager = WalletModelsManagerTestsMock()
        walletModelsManager.walletModels = [
            WalletModelTestsMock(
                tokenItem: .blockchain(network),
                isEmpty: false,
                account: CryptoAccountModelMock(isMainAccount: true, userTokensManager: userTokensManager, onArchive: { _ in })
            ),
        ]

        return CampaignUserWalletModelStub(
            walletIdSeed: seed,
            userTokensManager: userTokensManager,
            walletModelsManager: walletModelsManager
        )
    }
}
