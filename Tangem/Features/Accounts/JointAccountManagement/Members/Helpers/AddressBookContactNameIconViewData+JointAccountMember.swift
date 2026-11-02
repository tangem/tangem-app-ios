//
//  AddressBookContactNameIconViewData+JointAccountMember.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension AddressBookContactNameIconViewData {
    init(jointAccountMember member: JointAccountMember, at index: Int) {
        self.init(
            letter: member.name.prefix(1).uppercased(),
            color: CompositeIconColorPalette.color(for: .jointAccountMember(at: index))
        )
    }
}
