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

    static func pendingOperationsRecord(operations: [JointAccountOperation]) -> JointAccountOperations {
        JointAccountOperations(cryptoAccountId: caseFlippedCryptoAccountId, operations: operations)
    }

    static func coinTransfer(
        id: String = "coin",
        status: JointAccountOperationStatus = .awaitingSignatures,
        finishedAt: Date? = nil,
        initiator: String = "0x7e5fb2c1a9d3e5f70241c6b8a91cd9c1e7f45bdf",
        signatures: [JointAccountOperation.Signature] = [],
        createdAt: Date = Date(timeIntervalSince1970: 1_757_323_237),
        threshold: Int = 2
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
            signatures: signatures,
            createdAt: createdAt,
            threshold: threshold
        )
    }
}

// MARK: - Keys

extension JointAccountCompositionFixture {
    static let ownAddress = Signed.member1Address
    static let strangerAddress = "0x2b5ad9c1e7f40638b2c1a9d3e5f70241c6b8a91c"
    static let seedKey = Data(hexString: "0279BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798")
    static let derivedKey = ExtendedPublicKey(
        publicKey: seedKey,
        chainCode: Data(repeating: 0x11, count: 32)
    )

    static var ownKeyPath: DerivationPath {
        get throws {
            try JointAccountKeyPath.derivationPath(forAccountAtIndex: derivationIdentity.derivationIndex)
        }
    }

    static var ownKeyDerivation: DerivationResult {
        get throws {
            try [seedKey: DerivedKeys(keys: [ownKeyPath: derivedKey])]
        }
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
        userRoleService: JointAccountUserRoleService,
        cryptoAccountsRepository: CryptoAccountsRepository = CryptoAccountsRepositoryStub(cryptoAccounts: [Signed.cryptoAccount()])
    ) -> CommonJointAccountStatusProvider {
        CommonJointAccountStatusProvider(
            userWalletId: userWalletId,
            derivationIdentity: derivationIdentity,
            jointAccountsRepository: repository,
            cryptoAccountsRepository: cryptoAccountsRepository,
            userRoleService: userRoleService
        )
    }
}

// MARK: - Signed composition

extension JointAccountCompositionFixture {
    enum Signed {
        static let config = JointAccountSignedConfig(name: "Joint account", icon: "Family", iconColor: "Azure", membersCount: 3, threshold: 2)
        static let safeAddress = "0x8f3a1c5e7b9d0246a8c0e2b4d6f8a0c2e4b6c21b"
        static let checksummedSafeAddress = "0x8f3a1C5e7b9D0246A8C0E2B4D6F8a0c2E4B6c21B"

        static let member1Address = "0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf"
        static let member2Address = "0x2B5AD5c4795c026514f8317c7a215E218DcCD6cF"
        static let member3Address = "0x6813Eb9362372EEF6200f3b1dbC3f819671cBA69"

        static let member1Signature = "0x4716923e895bf6b93c2c146e7d7b0e829b4a32ec4c615f1283812da02eb8806906e07621fd58c9d619482899da61a20ffe1ce7a9ef57c7ced8ebb997e82d38d31b"
        static let member2Signature = "0x28a2519e0f3909bcba3113e789b33e1329f740c8eca6c4340f20b3e2e9df48e51620d0f68fb74f131af44fe0060fefcb612eaccaaec9eb0bc518bbd7367e72dd1c"
        static let member3Signature = "0x1d0455986d39d28eebd18693545114ee57fcc473634ec0f14330edeb44026a990e960a1079c02bfbf0a98620ac3bef4471f135f6d591a3489d836d8814116cdb1c"

        static var signedMembers: [StoredJointAccount.Member] {
            account(status: .active(safeAddress: safeAddress)).members
        }

        static func account(status: JointAccountStatus) -> StoredJointAccount {
            storedAccount(
                status: status,
                membersCount: config.membersCount,
                members: [member1Address, member2Address, member3Address].map { member(address: $0) },
                memberSignatures: [member1Signature, member2Signature, member3Signature]
            )
        }

        static func cryptoAccount(name: String? = config.name) -> StoredCryptoAccount {
            StoredCryptoAccount(
                derivationIndex: derivationIdentity.derivationIndex,
                type: .joint,
                name: name,
                icon: StoredCryptoAccount.Icon(iconName: config.icon, iconColor: config.iconColor),
                tokens: [],
                grouping: .none,
                sorting: .manual
            )
        }
    }
}
