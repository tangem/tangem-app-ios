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
    var expressProvidersPublisher: AnyPublisher<[ExpressAvailableProvider], Never> { get }
    var selectedExpressProviderPublisher: AnyPublisher<ExpressAvailableProvider?, Never> { get }
}

protocol SendSwapProvidersOutput: AnyObject {
    func userDidSelect(provider: ExpressAvailableProvider)
}
