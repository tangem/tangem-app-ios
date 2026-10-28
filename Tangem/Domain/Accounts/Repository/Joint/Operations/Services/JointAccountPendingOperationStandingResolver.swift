//
//  JointAccountPendingOperationStandingResolver.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct JointAccountPendingOperationStandingResolver {
    func standing(for pendingOperation: JointAccountPendingOperation) -> JointAccountPendingOperation.Standing {
        guard let ownAddress = pendingOperation.wallet.ownAddress else {
            return .noDecisionYet
        }

        guard !pendingOperation.isInitiator else {
            return .signed
        }

        let signature = pendingOperation.operation.signatures.first { $0.address.caseInsensitiveEquals(to: ownAddress) }

        return switch signature?.state {
        case .signed: .signed
        case .declined: .declined
        case .unknown, .none: .noDecisionYet
        }
    }

    func canSign(_ pendingOperation: JointAccountPendingOperation) -> Bool {
        guard let ownAddress = answeringAddress(of: pendingOperation), !pendingOperation.isInitiator else {
            return false
        }

        return !pendingOperation.operation.signatures.contains { $0.address.caseInsensitiveEquals(to: ownAddress) }
    }

    func canReject(_ pendingOperation: JointAccountPendingOperation) -> Bool {
        answeringAddress(of: pendingOperation) != nil && standing(for: pendingOperation) != .declined
    }
}

// MARK: - Private

private extension JointAccountPendingOperationStandingResolver {
    func answeringAddress(of pendingOperation: JointAccountPendingOperation) -> String? {
        guard pendingOperation.operation.status == .awaitingSignatures else {
            return nil
        }

        return pendingOperation.wallet.ownAddress
    }
}
