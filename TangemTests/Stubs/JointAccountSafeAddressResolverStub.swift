//
//  JointAccountSafeAddressResolverStub.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
@testable import Tangem

final class JointAccountSafeAddressResolverStub: JointAccountSafeAddressResolver {
    private let accountSafesLock: OSAllocatedUnfairLock<[JointAccountSafe]>
    private let didUpdateSubject = PassthroughSubject<Void, Never>()

    var didUpdatePublisher: AnyPublisher<Void, Never> {
        didUpdateSubject.eraseToAnyPublisher()
    }

    var accountSafes: [JointAccountSafe] {
        accountSafesLock.withLock { $0 }
    }

    init(accountSafes: [JointAccountSafe] = []) {
        accountSafesLock = OSAllocatedUnfairLock(initialState: accountSafes)
    }

    func store(accountSafes: [JointAccountSafe]) {
        accountSafesLock.withLock { $0 = accountSafes }
        didUpdateSubject.send()
    }
}
