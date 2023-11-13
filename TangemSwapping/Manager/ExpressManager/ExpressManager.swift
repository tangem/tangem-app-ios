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
    nonisolated var providersPublisher: AnyPublisher<[ExpressProvider], Never> { get }
    nonisolated var availableQuotesPublisher: AnyPublisher<[ExpectedQuote], Never> { get }
    nonisolated var selectedQuotePublisher: AnyPublisher<ExpectedQuote?, Never> { get }

    func getPair() async -> ExpressManagerSwappingPair?
    func updatePair(pair: ExpressManagerSwappingPair) async throws -> ExpressManagerState

    func getAmount() async -> Decimal?
    func updateAmount(amount: Decimal?) async throws -> ExpressManagerState

    func getSelectedProvider() async -> ExpressProvider?
    func updateSelectedProvider(provider: ExpressProvider) async throws -> ExpressManagerState

    func update() async throws -> ExpressManagerState
}
