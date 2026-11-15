//
//  JointAccountStatusProviderStub.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct JointAccountStatusProviderStub: JointAccountStatusProvider {
    let status: JointAccountStatus

    var statusPublisher: AnyPublisher<JointAccountStatus, Never> {
        Just(status).eraseToAnyPublisher()
    }
}
