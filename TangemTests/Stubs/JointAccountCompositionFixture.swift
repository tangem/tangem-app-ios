//
//  JointAccountCompositionFixture.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSdk
import TangemFoundation
@testable import Tangem

/// The records a wallet holds for one joint account, and the real service that reads them back, so that a test checks
/// its subject against the composition the app would put together rather than one written out by hand.
enum JointAccountCompositionFixture {
    static let userWalletId = UserWalletId(value: Data(repeating: 0xAB, count: 32))
    static let derivationIdentity = CryptoAccountDerivationIdentity(derivationIndex: 1, type: .joint)

    /// The account's identifier with the case of every letter flipped: the endpoint spells it its own way, and every
    /// reader of these records has to find them regardless.
    static var caseFlippedCryptoAccountId: String {
        let identifier = CryptoAccountModelId(userWalletId: userWalletId, derivationIdentity: derivationIdentity).rawValue.hexString

        return String(identifier.map { $0.isUppercase ? Character($0.lowercased()) : Character($0.uppercased()) })
    }

    /// - Parameter memberSlots: The slot of each member, as only the creator of a pending account is told them;
    /// nil for everyone else.
    static func makeMembersService(
        status: JointAccountStatus = .pending,
        membersCount: Int,
        members: [JointAccountMember],
        memberSlots: [Int]? = nil,
        memberSignatures: [String?]? = nil,
        invites: [StoredJointAccount.Invite] = [],
        userRoleService: JointAccountUserRoleService? = nil,
        keysProvider: KeysProvider = KeysRepositoryTestsMock(keys: [])
    ) -> CommonJointAccountMembersService {
        let repository = JointAccountsRepositoryStub(
            jointAccounts: [
                storedAccount(
                    status: status,
                    membersCount: membersCount,
                    members: members,
                    memberSlots: memberSlots,
                    memberSignatures: memberSignatures,
                    invites: invites
                ),
            ]
        )

        return makeMembersService(repository: repository, userRoleService: userRoleService, keysProvider: keysProvider)
    }

    static func makeMembersService(
        repository: JointAccountsRepository,
        userRoleService: JointAccountUserRoleService? = nil,
        keysProvider: KeysProvider = KeysRepositoryTestsMock(keys: [])
    ) -> CommonJointAccountMembersService {
        CommonJointAccountMembersService(
            userWalletId: userWalletId,
            derivationIdentity: derivationIdentity,
            jointAccountsRepository: repository,
            userRoleService: userRoleService ?? makeUserRoleService(repository: repository, keysProvider: keysProvider)
        )
    }

    static func makeUserRoleService(repository: JointAccountsRepository, keysProvider: KeysProvider) -> CommonJointAccountUserRoleService {
        CommonJointAccountUserRoleService(
            userWalletId: userWalletId,
            derivationIdentity: derivationIdentity,
            keysProvider: keysProvider,
            jointAccountsRepository: repository
        )
    }

    static func storedAccount(
        status: JointAccountStatus,
        membersCount: Int,
        members: [JointAccountMember],
        memberSlots: [Int]? = nil,
        memberSignatures: [String?]? = nil,
        invites: [StoredJointAccount.Invite] = []
    ) -> StoredJointAccount {
        StoredJointAccount(
            cryptoAccountId: caseFlippedCryptoAccountId,
            membersCount: membersCount,
            threshold: 2,
            status: status,
            members: members.enumerated().map { index, member in
                StoredJointAccount.Member(
                    name: member.name,
                    address: member.address,
                    role: member.role == .creator ? .creator : .member,
                    slot: memberSlots?[safe: index].map(JointAccountMemberSlotID.init),
                    signature: memberSignatures?[safe: index] ?? nil
                )
            },
            invites: invites
        )
    }

    static func pendingOperationsRecord(operations: [JointAccountOperation]) -> StoredJointAccountPendingOperations {
        StoredJointAccountPendingOperations(cryptoAccountId: caseFlippedCryptoAccountId, operations: operations)
    }

    static func coinTransfer(
        id: String = "coin",
        status: JointAccountOperationStatus = .awaitingSignatures,
        finishedAt: Date? = nil,
        initiator: String = "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf",
        signatures: [JointAccountOperation.Signature] = []
    ) -> JointAccountOperation {
        JointAccountOperation(
            id: id,
            chainId: 1,
            safeTransaction: SafeTransaction(
                to: "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c",
                value: 1_000_000_000_000_000,
                data: Data(),
                operation: 0,
                safeTxGas: 0,
                baseGas: 100_000,
                gasPrice: 1_000_000_000,
                gasToken: SafeGasToken.coinGasTokenRawValue,
                refundReceiver: "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf",
                nonce: 0
            ),
            status: status,
            txHash: nil,
            finishedAt: finishedAt,
            cancelReason: nil,
            initiator: initiator,
            signatures: signatures
        )
    }
}

// MARK: - Keys

extension JointAccountCompositionFixture {
    static let ownAddress = "0x6ECa00c52AFC728CDbF42E817d712e175bb23C7d"
    static let strangerAddress = "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c"
    static let seedKey = Data(hexString: "0279BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798")
    static let derivedKey = ExtendedPublicKey(
        publicKey: Data(hexString: "0241DCD64B5F4A039FC339A16300A833A883B218909F2EBCAF3906651C76842C45"),
        chainCode: Data(repeating: 0x11, count: 32)
    )

    static var ownKeyPath: DerivationPath {
        JointAccountKeyPath.derivationPath(forAccountAtIndex: derivationIdentity.derivationIndex)
    }

    static var ownKeyDerivation: DerivationResult {
        [seedKey: DerivedKeys(keys: [ownKeyPath: derivedKey])]
    }

    static func masterKey(derivedKeys: [DerivationPath: ExtendedPublicKey] = [:]) -> KeyInfo {
        KeyInfo(
            publicKey: seedKey,
            chainCode: Data(repeating: 0x11, count: 32),
            curve: .secp256k1,
            isImported: false,
            derivedKeys: derivedKeys
        )
    }

    static func member(address: String, role: JointAccountMember.Role = .member) -> JointAccountMember {
        JointAccountMember(name: "Member", address: address, role: role, isMe: false, signature: nil)
    }

    static func makeStatusProvider(
        repository: JointAccountsRepository,
        userRoleService: JointAccountUserRoleService
    ) -> CommonJointAccountStatusProvider {
        CommonJointAccountStatusProvider(
            userWalletId: userWalletId,
            derivationIdentity: derivationIdentity,
            jointAccountsRepository: repository,
            userRoleService: userRoleService
        )
    }
}
