//
//  AccountBlockchainManageabilityCheckerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("Tests for the networks an account may hold tokens in")
struct AccountBlockchainManageabilityCheckerTests {
    private let delegate = JointAccountModelDelegateMock()

    @Test("A joint account manages the supported networks and their testnets alone, even among the EVM ones")
    func jointAccountManagesTheSupportedNetworksOnly() {
        let jointAccount = makeJointAccount()

        #expect(AccountBlockchainManageabilityChecker.canManageBlockchain(.polygon(testnet: false), for: jointAccount))
        #expect(AccountBlockchainManageabilityChecker.canManageBlockchain(.polygon(testnet: true), for: jointAccount))
        #expect(!AccountBlockchainManageabilityChecker.canManageBlockchain(.gnosis, for: jointAccount))
    }

    @Test("A joint account manages a network by its id only when the wallet supports it and it is on the list")
    func jointAccountManagesNetworksById() {
        let jointAccount = makeJointAccount()
        let supportedBlockchains: Set<Blockchain> = [.polygon(testnet: false), .gnosis]

        #expect(AccountBlockchainManageabilityChecker.canManageNetwork(Blockchain.polygon(testnet: false).networkId, for: jointAccount, in: supportedBlockchains))
        #expect(!AccountBlockchainManageabilityChecker.canManageNetwork(Blockchain.gnosis.networkId, for: jointAccount, in: supportedBlockchains))
        #expect(!AccountBlockchainManageabilityChecker.canManageNetwork(Blockchain.base(testnet: false).networkId, for: jointAccount, in: supportedBlockchains))
    }

    @Test("A wallet's own extra account still manages an EVM network outside the joint list")
    func extraAccountStillManagesEVMNetworks() {
        let extraAccount = CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in })

        #expect(AccountBlockchainManageabilityChecker.canManageBlockchain(.gnosis, for: extraAccount))
    }
}

// MARK: - Helpers

private extension AccountBlockchainManageabilityCheckerTests {
    func makeJointAccount() -> any JointAccountModel {
        CommonJointAccountModel(
            cryptoAccount: CryptoAccountModelMock(isMainAccount: false, onArchive: { _ in }),
            derivationIdentity: CryptoAccountDerivationIdentity(derivationIndex: 1, type: .joint),
            accountPolicy: JointAccountPolicy(membersCount: 2, signersCount: 2),
            accountStatus: .pending,
            operationsService: JointAccountOperationsServiceMock(),
            pendingOperationsProvider: JointAccountPendingOperationsProviderMock(),
            membersService: JointAccountMembersServiceMock(),
            delegate: delegate
        )
    }
}
