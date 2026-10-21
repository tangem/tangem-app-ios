//
//  JointAccountUserRoleService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol JointAccountUserRoleService {
    func role(among members: [JointAccountMember]) -> JointAccountUserRole
}

// MARK: - Auxiliary types

enum JointAccountUserRole: Equatable {
    case member(JointAccountMember)
    case outsider
    case derivationNeeded
}

extension JointAccountUserRole {
    var member: JointAccountMember? {
        switch self {
        case .member(let member): member
        case .outsider, .derivationNeeded: nil
        }
    }

    var isCreator: Bool {
        member?.role == .creator
    }
}
