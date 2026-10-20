//
//  SwapPredefinedParametersHelperJointAccountTests.swift
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

@Suite("Swap parameters for a joint account's token")
struct SwapPredefinedParametersHelperJointAccountTests {
    private let delegate = JointAccountModelDelegateMock()

    @Test("Opening a swap into a joint account's token makes it a receive-only destination")
    func jointAccountTokenOpensAsReceiveOnlyDestination() async throws {
        try await InjectedDependenciesIsolation.shared.run {
            let previousProvider = InjectedValues[\.expressAvailabilityProvider]
            InjectedValues[\.expressAvailabilityProvider] = SwapExpressAvailabilityProviderStub()
            defer { InjectedValues[\.expressAvailabilityProvider] = previousProvider }

            let walletModelsManager = WalletModelsManagerTestsMock()
            let destination = WalletModelTestsMock(
                tokenItem: .blockchain(.init(.polygon(testnet: false), derivationPath: nil)),
                isEmpty: true,
                account: makeJointAccount(walletModelsManager: walletModelsManager)
            )
            walletModelsManager.walletModels = [destination]

            let parameters = SwapPredefinedParametersHelper().makeParameters(
                walletModel: destination,
                userWalletInfo: makeUserWalletInfo(),
                position: .to
            )

            let receive = try #require(parameters.receiveToken)
            #expect(!(receive is SendSwapableToken))
        }
    }
}

// MARK: - Helpers

private extension SwapPredefinedParametersHelperJointAccountTests {
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
            config: UserWalletConfigStub(supportedBlockchains: [.polygon(testnet: false)]),
            backupState: .valid,
            refcode: nil,
            signerFactory: TangemSignerFactory(),
            emailDataProvider: EmailDataProviderStub()
        )
    }
}
