//
//  JointAccountInviteIssuer.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

protocol JointAccountInviteIssuer {
    func issueInvite(slot: JointAccountMemberSlotID) async throws(JointAccountInviteIssueError) -> JointAccountInvite
}

enum JointAccountInviteIssueError: Error {
    case slotUnavailable
    case unexpectedResponse
    case failed(Error)
}

// MARK: - LocalizedError

extension JointAccountInviteIssueError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .slotUnavailable, .unexpectedResponse:
            Localization.commonUnknownError
        case .failed(let error):
            error.localizedDescription
        }
    }
}
