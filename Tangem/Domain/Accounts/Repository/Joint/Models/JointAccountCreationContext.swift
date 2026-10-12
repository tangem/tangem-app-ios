//
//  JointAccountCreationContext.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum JointAccountCreationContextType {
    case creation(JointAccountCreationContext)
    case joining(JointAccountJoiningContext)

    /// Named by whoever the account comes from: the creator naming a new one, or the invite naming the one joined.
    var name: String {
        switch self {
        case .creation(let context): context.name
        case .joining(let context): context.name
        }
    }
}

struct JointAccountCreationContext {
    let name: String
    let icon: AccountModel.CompositeIcon
    let membersCount: Int
    let signersCount: Int
    let creatorName: String
}

struct JointAccountJoiningContext {
    let name: String
    let invite: String
}
