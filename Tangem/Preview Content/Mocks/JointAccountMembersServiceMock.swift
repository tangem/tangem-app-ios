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
    var issuedInvite: JointAccountInvite?

    var slotsPublisher: AnyPublisher<[JointAccountSlot], Never> {
        Just(slots).eraseToAnyPublisher()
    }

    func requestFrequentUpdates() -> AnyCancellable {
        AnyCancellable {}
    }

    func issueInvite(slot: JointAccountMemberSlotID) async throws(JointAccountInviteIssueError) -> JointAccountInvite {
        guard let issuedInvite else {
            throw .failed(CancellationError())
        }

        return issuedInvite
    }
}
