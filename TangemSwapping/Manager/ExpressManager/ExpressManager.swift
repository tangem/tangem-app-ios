//
//  ExpressManager.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public protocol ExpressManager {
    var providersPublisher: AnyPublisher<[ExpressProvider], Never> { get }
    var availableQuotesPublisher: AnyPublisher<[ExpectedQuote], Never> { get }
    var selectedQuotePublisher: AnyPublisher<ExpectedQuote?, Never> { get }

    func getPair() -> ExpressManagerSwappingPair?
    func updatePair(pair: ExpressManagerSwappingPair) async throws -> ExpressManagerState

    func getAmount() -> Decimal?
    func updateAmount(amount: Decimal?) async throws -> ExpressManagerState

    func getSelectedProvider() -> ExpressProvider?
    func updateSelectedProvider(provider: ExpressProvider) async throws -> ExpressManagerState

    func update() async throws -> ExpressManagerState
}
