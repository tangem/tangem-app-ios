//
//  JointAccountMemberIconViewData.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum JointAccountMemberIconViewData: Equatable {
    case member(AddressBookContactNameIconViewData)
    case vacant

    init(slot: JointAccountSlot, index: Int) {
        switch slot {
        case .member(let member, _):
            let viewData = AddressBookContactNameIconViewData(jointAccountMember: member, at: index)
            self = .member(viewData)
        case .empty:
            self = .vacant
        }
    }
}
