//
//  CommonJointAccountUserRoleService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemSdk

struct CommonJointAccountUserRoleService {
    private let cryptoAccountId: String
    private let derivationPath: DerivationPath
    private let keysProvider: KeysProvider
    private let jointAccountsRepository: JointAccountsRepository

    init(
        userWalletId: UserWalletId,
        derivationIdentity: CryptoAccountDerivationIdentity,
        keysProvider: KeysProvider,
        jointAccountsRepository: JointAccountsRepository
    ) {
        cryptoAccountId = CryptoAccountModelId(userWalletId: userWalletId, derivationIdentity: derivationIdentity).rawValue.hexString
        derivationPath = JointAccountKeyPath.derivationPath(forAccountAtIndex: derivationIdentity.derivationIndex)
        self.keysProvider = keysProvider
        self.jointAccountsRepository = jointAccountsRepository
    }
}

// MARK: - JointAccountUserRoleService protocol conformance

extension CommonJointAccountUserRoleService: JointAccountUserRoleService {
    func isCreator() throws(JointAccountUserRoleServiceError) -> Bool {
        guard
            let account = jointAccountsRepository.jointAccounts.first(by: cryptoAccountId),
            let creator = account.members.first(where: { $0.role == .creator })
        else {
            return false
        }

        do throws(JointAccountUserRoleServiceError) {
            return try isMe(member: creator)
        } catch {
            // [REDACTED_TODO_COMMENT]
            JointAccountsLogger.warning("This wallet's key of the joint account at \(derivationPath.rawPath) is not derived, so its own address is unknown")
            throw error
        }
    }

    func ownAddress() throws(JointAccountUserRoleServiceError) -> String {
        do {
            return try JointAccountDerivationUtils.storedDerivedKey(at: derivationPath, in: keysProvider).address
        } catch JointAccountDerivationUtils.Error.keyNotStored {
            throw .derivationNeeded
        } catch {
            JointAccountsLogger.error("Unable to work out this wallet's address in a joint account", error: error)
            throw .derivationNeeded
        }
    }
}
