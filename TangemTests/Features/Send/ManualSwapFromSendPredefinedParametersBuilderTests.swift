//
//  ManualSwapFromSendPredefinedParametersBuilderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Manual swap from Send parameters")
struct ManualSwapFromSendPredefinedParametersBuilderTests {
    private let ethereum = TokenItem.blockchain(BlockchainNetwork(.ethereum(testnet: false), derivationPath: nil))
    private let polygon = TokenItem.blockchain(BlockchainNetwork(.polygon(testnet: false), derivationPath: nil))

    @Test("A custom source is left to the user")
    func customSourceIsLeftToTheUser() async {
        let userWalletModel = makeUserWalletModel(walletModels: [])

        let parameters = await make(
            userWalletModel: userWalletModel,
            source: makeWalletModel(tokenItem: ethereum, isCustom: true)
        )

        #expect(parameters.source is UserSelectionSwapTokenResolver)
    }

    @Test("A joint account's token is never preselected as the source")
    func jointSourceIsLeftToTheUser() async {
        let userWalletModel = makeUserWalletModel(walletModels: [])

        let parameters = await make(
            userWalletModel: userWalletModel,
            source: makeWalletModel(tokenItem: ethereum, accountType: .joint)
        )

        #expect(parameters.source is UserSelectionSwapTokenResolver)
    }

    @Test("A receive token the wallet doesn't hold is left to the user")
    func missingReceiveIsLeftToTheUser() async {
        let userWalletModel = makeUserWalletModel(walletModels: [])

        let parameters = await make(
            userWalletModel: userWalletModel,
            source: makeWalletModel(tokenItem: ethereum, isCustom: true)
        )

        #expect(parameters.receive is UserSelectionSwapTokenResolver)
    }

    @Test("A custom receive token is left to the user")
    func customReceiveIsLeftToTheUser() async {
        let userWalletModel = makeUserWalletModel(walletModels: [makeWalletModel(tokenItem: polygon, isCustom: true)])

        let parameters = await make(
            userWalletModel: userWalletModel,
            source: makeWalletModel(tokenItem: ethereum, isCustom: true)
        )

        #expect(parameters.receive is UserSelectionSwapTokenResolver)
    }

    @Test("A joint account's receive token is preselected as receive-only")
    func jointReceiveIsReceiveOnly() async throws {
        let userWalletModel = makeUserWalletModel(walletModels: [makeWalletModel(tokenItem: polygon, accountType: .joint)])

        let parameters = await make(
            userWalletModel: userWalletModel,
            source: makeWalletModel(tokenItem: ethereum, isCustom: true)
        )

        let receive = try #require(parameters.receive as? ResolvedSwapReceiveTokenResolver)
        #expect(receive.token.tokenItem == polygon)
        #expect(!(receive.token is SendSwapableToken))
    }
}

// MARK: - Fixtures

private extension ManualSwapFromSendPredefinedParametersBuilderTests {
    func make(userWalletModel: CampaignUserWalletModelStub, source: WalletModelTestsMock) async -> PredefinedSwapParameters {
        await InjectedDependenciesIsolation.shared.run {
            let previousRepository = InjectedValues[\.userWalletRepository]
            let previousExpressProvider = InjectedValues[\.expressAvailabilityProvider]
            InjectedValues[\.userWalletRepository] = FakeUserWalletRepository(models: [userWalletModel])
            InjectedValues[\.expressAvailabilityProvider] = SwapExpressAvailabilityProviderStub()
            defer {
                InjectedValues[\.userWalletRepository] = previousRepository
                InjectedValues[\.expressAvailabilityProvider] = previousExpressProvider
            }

            let builder = ManualSwapFromSendPredefinedParametersBuilder(
                userWalletId: userWalletModel.userWalletId,
                source: WalletModelFinder.Result(userWalletModel: userWalletModel, walletModel: source),
                receiveTokenItem: polygon
            )

            return builder.make()
        }
    }

    func makeUserWalletModel(walletModels: [WalletModelTestsMock]) -> CampaignUserWalletModelStub {
        let walletModelsManager = WalletModelsManagerTestsMock()
        walletModelsManager.walletModels = walletModels

        return CampaignUserWalletModelStub(walletIdSeed: "manual-swap", walletModelsManager: walletModelsManager)
    }

    func makeWalletModel(tokenItem: TokenItem, isCustom: Bool = false, accountType: AccountType = .crypto) -> WalletModelTestsMock {
        WalletModelTestsMock(
            tokenItem: tokenItem,
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
}
