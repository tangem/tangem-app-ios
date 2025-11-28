//
//  RefreshStatusProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

protocol RefreshStatusProvider: AnyObject {
    var isRefreshing: AnyPublisher<Bool, Never> { get }
}
