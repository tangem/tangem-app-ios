//
//  JointAccountSafeAddressProviderStub.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
@testable import Tangem

/// Hands out whatever address a test tells it to, with the real provider's contract: the current value first, no repeats.
final class JointAccountSafeAddressProviderStub: JointAccountSafeAddressProvider {
    private let safeAddressSubject: CurrentValueSubject<String?, Never>

    var safeAddress: String? {
        safeAddressSubject.value
    }

    var safeAddressPublisher: AnyPublisher<String?, Never> {
        safeAddressSubject.removeDuplicates().eraseToAnyPublisher()
    }

    init(safeAddress: String? = nil) {
        safeAddressSubject = CurrentValueSubject(safeAddress)
    }

    /// What activation would have handed the account.
    func send(_ safeAddress: String?) {
        safeAddressSubject.send(safeAddress)
    }
}
