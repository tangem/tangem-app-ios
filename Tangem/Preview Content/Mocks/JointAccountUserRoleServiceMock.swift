//
//  JointAccountUserRoleServiceMock.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct JointAccountUserRoleServiceMock: JointAccountUserRoleService {
    var creator = false
    /// Nil for a wallet that has not derived the account's key.
    var address: String?

    func isCreator() throws(JointAccountUserRoleServiceError) -> Bool {
        creator
    }

    func ownAddress() throws(JointAccountUserRoleServiceError) -> String {
        guard let address else {
            throw .derivationNeeded
        }

        return address
    }
}
