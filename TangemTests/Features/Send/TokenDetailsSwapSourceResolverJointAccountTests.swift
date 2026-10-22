//
//  TokenDetailsSwapSourceResolverJointAccountTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
import TangemFoundation
@testable import Tangem

@Suite("Token details swap source for a joint account's token")
struct TokenDetailsSwapSourceResolverJointAccountTests {
    private let delegate = JointAccountModelDelegateMock()

    @Test("A joint account's funded sibling token is never picked as the source for a swap into it")
    func jointAccountSiblingIsNotPickedAsSource() async {
        await InjectedDependenciesIsolation.shared.run {
            let previousProvider = InjectedValues[\.expressAvailabilityProvider]
            InjectedValues[\.expressAvailabilityProvider] = SwapExpressAvailabilityProviderStub()
            defer { InjectedValues[\.expressAvailabilityProvider] = previousProvider }

            let walletModelsManager = WalletModelsManagerTestsMock()
            let jointAccount = makeJointAccount(walletModelsManager: walletModelsManager)
            let destination = WalletModelTestsMock(
                tokenItem: .blockchain(.init(.polygon(testnet: false), derivationPath: nil)),
                isEmpty: true,
                account: jointAccount
            )
            let fundedSibling = WalletModelTestsMock(
                tokenItem: .blockchain(.init(.ethereum(testnet: false), derivationPath: nil)),
                isEmpty: false,
                fiatBalance: 100,
                account: jointAccount
            )
            walletModelsManager.walletModels = [destination, fundedSibling]

            let sut = TokenDetailsSwapSourceResolver(userWalletInfo: makeUserWalletInfo())

            #expect(sut.resolveSource(for: destination) == nil)
        }
    }
}

// MARK: - Helpers

private extension TokenDetailsSwapSourceResolverJointAccountTests {
    func makeJointAccount(walletModelsManager: WalletModelsManager) -> any JointAccountModel {
        CommonJointAccountModel(
            cryptoAccount: CryptoAccountModelMock(
                isMainAccount: false,
                accountType: .joint,
                walletModelsManager: walletModelsManager,
                onArchive: { _ in }
            ),
            derivationIdentity: CryptoAccountDerivationIdentity(derivationIndex: 1, type: .joint),
            accountPolicy: JointAccountPolicy(membersCount: 2, signersCount: 2),
            accountStatus: .pending,
            operationsService: JointAccountOperationsServiceMock(),
            pendingOperationsProvider: JointAccountPendingOperationsProviderMock(),
            membersService: JointAccountMembersServiceMock(),
            delegate: delegate
        )
    }

    func makeUserWalletInfo() -> UserWalletInfo {
        UserWalletInfo(
            name: "Test",
            id: UserWalletId(value: Data([0x01])),
            config: UserWalletConfigStub(supportedBlockchains: [.polygon(testnet: false), .ethereum(testnet: false)]),
            backupState: .valid,
            refcode: nil,
            signerFactory: TangemSignerFactory(),
            emailDataProvider: EmailDataProviderStub()
        )
    }
}
