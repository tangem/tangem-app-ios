//
//  TransactionHistoryService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol TransactionHistoryService: AnyObject {
    var canFetchMore: Bool { get }

    var state: TransactionHistoryServiceState { get }
    var statePublisher: AnyPublisher<TransactionHistoryServiceState, Never> { get }

    var items: [TransactionRecord] { get }

    /// Use this method for reset manager to first page
    func reset()

    /// Use this method for reset manager to first page
    func update() -> AnyPublisher<Void, Error>
}
