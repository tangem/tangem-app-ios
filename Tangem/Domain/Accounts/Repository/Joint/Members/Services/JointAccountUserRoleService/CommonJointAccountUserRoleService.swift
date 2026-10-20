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
    private let derivationPath: DerivationPath
    private let keysProvider: KeysProvider

    init(derivationIdentity: CryptoAccountDerivationIdentity, keysProvider: KeysProvider) {
        derivationPath = JointAccountKeyPath.derivationPath(forAccountAtIndex: derivationIdentity.derivationIndex)
        self.keysProvider = keysProvider
    }
}

// MARK: - JointAccountUserRoleService protocol conformance

extension CommonJointAccountUserRoleService: JointAccountUserRoleService {
    func role(among members: [JointAccountMember]) -> JointAccountUserRole {
        guard !members.isEmpty else {
            return .outsider
        }

        let address: String

        do {
            address = try JointAccountDerivationUtils.storedDerivedKey(at: derivationPath, in: keysProvider).address
        } catch JointAccountDerivationUtils.Error.keyNotStored {
            // [REDACTED_TODO_COMMENT]
            return .derivationNeeded
        } catch {
            JointAccountsLogger.error("Unable to work out this wallet's address in a joint account", error: error)
            return .derivationNeeded
        }

        guard let member = members.first(where: { $0.address.caseInsensitiveEquals(to: address) }) else {
            return .outsider
        }

        return .member(member)
    }
}
