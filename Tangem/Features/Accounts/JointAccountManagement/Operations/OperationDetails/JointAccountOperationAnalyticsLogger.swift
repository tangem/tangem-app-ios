//
//  JointAccountOperationAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol JointAccountOperationAnalyticsLogger {
    func logOperationSigned(_ operation: JointAccountOperation)
    func logSigningFailed(error: Error)
    func logRejectionFailed(error: Error, isInitiator: Bool)
}

struct CommonJointAccountOperationAnalyticsLogger {
    private let tokenItem: TokenItem
    private let policy: JointAccountPolicy?

    init(tokenItem: TokenItem, policy: JointAccountPolicy?) {
        self.tokenItem = tokenItem
        self.policy = policy
    }
}

// MARK: - JointAccountOperationAnalyticsLogger

extension CommonJointAccountOperationAnalyticsLogger: JointAccountOperationAnalyticsLogger {
    func logOperationSigned(_ operation: JointAccountOperation) {
        Analytics.log(event: .jointAccountOperationSigned, params: operationSignedParameters(for: operation))
    }

    func logSigningFailed(error: Error) {
        Analytics.logJointAccountError(source: .sign, error: error)
    }

    func logRejectionFailed(error: Error, isInitiator: Bool) {
        Analytics.logJointAccountError(source: isInitiator ? .delete : .decline, error: error)
    }
}

// MARK: - Parameters

extension CommonJointAccountOperationAnalyticsLogger {
    func operationSignedParameters(for operation: JointAccountOperation) -> [Analytics.ParameterKey: String] {
        let signersCount = operation.signersCount

        var params: [Analytics.ParameterKey: String] = [
            .signaturesCollected: "\(signersCount)",
            .blockchain: tokenItem.blockchain.displayName,
            .token: tokenItem.currencySymbol,
        ]

        if let policy {
            params[.membersCount] = "\(policy.membersCount)"
            params[.threshold] = "\(policy.signersCount)"
            params[.thresholdReached] = Analytics.ParameterValue.affirmativeOrNegative(for: signersCount >= policy.signersCount).rawValue
        }

        return params
    }
}

// MARK: - Signers

private extension JointAccountOperation {
    var signersCount: Int {
        let signers = signatures
            .filter { $0.state == .signed }
            .map { $0.address.lowercased() }

        return Set(signers + [initiator.lowercased()]).count
    }
}
