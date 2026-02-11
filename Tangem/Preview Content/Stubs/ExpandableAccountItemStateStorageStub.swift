//
//  ExpandableAccountItemStateStorageStub.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct ExpandableAccountItemStateStorageStub {
    let isExpanded: Bool
}

// MARK: - ExpandableAccountItemStateStorage protocol conformance

extension ExpandableAccountItemStateStorageStub: ExpandableAccountItemStateStorage {
    var didUpdatePublisher: AnyPublisher<Void, Never> { .empty }

    func isExpanded(_ accountModel: some BaseAccountModel) -> Bool {
        isExpanded
    }

    func setIsExpanded(_ isExpanded: Bool, for accountModel: some BaseAccountModel) {
        // No-op
    }
}
