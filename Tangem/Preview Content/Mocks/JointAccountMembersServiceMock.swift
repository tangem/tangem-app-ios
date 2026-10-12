//
//  JointAccountMembersServiceMock.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct JointAccountMembersServiceMock: JointAccountMembersService {
    var slots: [JointAccountSlot] = []
    var isCreatorDevice = false

    var slotsPublisher: AnyPublisher<[JointAccountSlot], Never> {
        Just(slots).eraseToAnyPublisher()
    }
}
