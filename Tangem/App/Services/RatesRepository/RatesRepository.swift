//
//  RatesRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

typealias Rates = [String: Decimal]

protocol RatesRepository: AnyObject {
    var rates: Rates { get }
    var ratesPublisher: AnyPublisher<Rates, Never> { get }

    // TBD: Do we need update?
    func update() -> AnyPublisher<Rates, Never>
    func update() async throws -> Rates
    func loadRates(coinIds: [String]) -> AnyPublisher<Rates, Never>
    func loadRates(coinIds: [String]) async throws -> Rates
    func rate(for coinId: String) async throws -> Decimal
}

private struct RatesProviderKey: InjectionKey {
    static var currentValue: RatesRepository = CommonRatesRepository()
}

extension InjectedValues {
    var ratesRepository: RatesRepository {
        get { Self[RatesProviderKey.self] }
        set { Self[RatesProviderKey.self] = newValue }
    }
}
