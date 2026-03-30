//
//  SendSwapProvidersInputOutput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress
import TangemFoundation

protocol SendSwapProvidersInput: AnyObject {
    var expressProviders: [ExpressAvailableProvider] { get }
    var expressProvidersPublisher: AnyPublisher<[ExpressAvailableProvider], Never> { get }

    var selectedExpressProvider: LoadingResult<ExpressAvailableProvider, any Error>? { get }
    var selectedExpressProviderPublisher: AnyPublisher<LoadingResult<ExpressAvailableProvider, any Error>?, Never> { get }

    var providerRateTypesPublisher: AnyPublisher<Set<ExpressProviderRateType>, Never> { get }
}

extension SendSwapProvidersInput {
    var providerRateTypesPublisher: AnyPublisher<Set<ExpressProviderRateType>, Never> {
        expressProvidersPublisher
            .map { providers in
                providers.reduce(into: Set<ExpressProviderRateType>()) { $0.formUnion($1.supportedRateTypes) }
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

protocol SendSwapProvidersOutput: AnyObject {
    func userDidSelect(provider: ExpressAvailableProvider)
}
