//
//  JointAccountUserRoleService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol JointAccountUserRoleService {
    func isCreator() throws(JointAccountUserRoleServiceError) -> Bool
    func ownAddress() throws(JointAccountUserRoleServiceError) -> String
}

extension JointAccountUserRoleService {
    var isCreator: Bool? { try? isCreator() }
    var ownAddress: String? { try? ownAddress() }

    func isMe(member: StoredJointAccount.Member) throws(JointAccountUserRoleServiceError) -> Bool {
        try ownAddress().caseInsensitiveEquals(to: member.address)
    }
}

// MARK: - Auxiliary types

enum JointAccountUserRoleServiceError: Error {
    case derivationNeeded
}
