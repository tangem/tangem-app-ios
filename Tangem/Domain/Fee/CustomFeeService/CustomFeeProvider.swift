//
//  FeeSelectorCustomFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

typealias CustomFeeProvider = FeeSelectorCustomFeeProvider & FeeSelectorCustomFeeFieldsBuilder & FeeSelectorCustomFeeAvailabilityProvider

protocol FeeSelectorCustomFeeProvider {
    var customFee: TokenFee { get }
    var customFeePublisher: AnyPublisher<TokenFee, Never> { get }

    func initialSetupCustomFee(_ fee: BSDKFee)
}

protocol FeeSelectorCustomFeeFieldsBuilder {
    func buildCustomFeeFields() -> [FeeSelectorCustomFeeRowViewModel]
}

protocol FeeSelectorCustomFeeAvailabilityProvider {
    var customFeeIsValid: Bool { get }
    var customFeeIsValidPublisher: AnyPublisher<Bool, Never> { get }

    func captureCustomFeeFieldsValue()
    func resetCustomFeeFieldsValue()
}
