//
//  JointAccountPendingOperationsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// The unfinished operations of one joint account, as the listing last reported them.
/// - Note: What they are followed through — the wallet's store of every account's operations — outlives the account,
/// so a subscription belongs to whoever subscribes rather than to the provider handing the publisher out.
protocol JointAccountPendingOperationsProvider {
    func hasPendingOperations(chainId: Int) -> Bool

    var pendingOperationsPublisher: AnyPublisher<[JointAccountPendingOperation], Never> { get }

    func requestFrequentUpdates(operationId: String) -> AnyCancellable?

    func pendingOperation(from operation: JointAccountOperation) async throws -> JointAccountPendingOperation

    func loadOperation(id: String) async throws -> JointAccountPendingOperation
}

enum JointAccountPendingOperationsProviderError: Error {
    /// The account has no wallet of the token on this device — another member may have added it.
    case walletNotFound
}
