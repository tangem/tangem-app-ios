//
//  TokenFeeProvidersManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress
import TangemFoundation

protocol TokenFeeProvidersManager: ExpressFeeProvider {
    var selectedFeeProvider: any TokenFeeProvider { get }
    var selectedFeeProviderPublisher: AnyPublisher<any TokenFeeProvider, Never> { get }

    var tokenFeeProviders: [any TokenFeeProvider] { get }
    var supportFeeSelection: Bool { get }
    var supportFeeSelectionPublisher: AnyPublisher<Bool, Never> { get }

    func update(feeOption: FeeOption)
    func update(input: TokenFeeProviderInputData)

    func updateSelectedFeeProvider(feeTokenItem: TokenItem)
}

// Proxy from `selectedFeeProvider`

extension TokenFeeProvidersManager {
    var selectedTokenFee: TokenFee {
        selectedFeeProvider.selectedTokenFee
    }

    var selectedTokenFeePublisher: AnyPublisher<TokenFee, Never> {
        selectedFeeProviderPublisher.flatMapLatest { $0.selectedTokenFeePublisher }.eraseToAnyPublisher()
    }
}
