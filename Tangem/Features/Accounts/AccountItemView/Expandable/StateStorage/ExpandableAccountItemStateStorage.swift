//
//  ExpandableAccountItemStateStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// User wallet-specific storage for expandable account item states, single instance per user wallet.
protocol ExpandableAccountItemStateStorage {
    var didUpdatePublisher: AnyPublisher<Void, Never> { get }

    func isExpanded(_ accountModel: some BaseAccountModel) -> Bool
    func setIsExpanded(_ isExpanded: Bool, for accountModel: some BaseAccountModel)
}
