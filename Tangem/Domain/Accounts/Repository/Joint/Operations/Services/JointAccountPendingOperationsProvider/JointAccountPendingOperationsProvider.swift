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
    var pendingOperations: [JointAccountPendingOperation] { get }

    var pendingOperationsPublisher: AnyPublisher<[JointAccountPendingOperation], Never> { get }

    func requestFrequentUpdates() -> AnyCancellable
}
