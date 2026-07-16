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

    /// True while the unfunded hot wallet limits the visible providers to DEX only
    var isDexOnlyProvidersMode: Bool { get }

    var selectedExpressProvider: LoadingResult<ExpressAvailableProvider, any Error>? { get }
    var selectedExpressProviderPublisher: AnyPublisher<LoadingResult<ExpressAvailableProvider, any Error>?, Never> { get }

    var providerRateTypesPublisher: AnyPublisher<Set<ExpressProviderRateType>, Never> { get }

    var currentRateType: ExpressProviderRateType? { get }
    var currentRateTypePublisher: AnyPublisher<ExpressProviderRateType?, Never> { get }
}

protocol SendSwapProvidersOutput: AnyObject {
    func userDidSelect(provider: ExpressAvailableProvider)
}

protocol SendSwapProvidersRoutable: AnyObject {
    func openLearnMoreAboutApprove()
}

protocol SwapApproveInput: AnyObject {
    var approvePolicy: BSDKApprovePolicy { get }
}

protocol SwapApproveOutput: AnyObject {
    func userDidSelectApprovePolicy(_ policy: BSDKApprovePolicy)
}
