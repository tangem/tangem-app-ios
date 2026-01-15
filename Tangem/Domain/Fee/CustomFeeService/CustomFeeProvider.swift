//
//  CustomFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

protocol CustomFeeProvider: FeeSelectorCustomFeeFieldsBuilder, FeeSelectorCustomFeeAvailabilityProvider {
    var customFee: LoadableTokenFee { get }
    var customFeePublisher: AnyPublisher<LoadableTokenFee, Never> { get }

    func initialSetupCustomFee(_ fee: BSDKFee)
}

extension CustomFeeProvider {
    func subscribeToInitialSetup(tokenFeeProvider: any TokenFeeProvider) -> AnyCancellable {
        tokenFeeProvider.feesPublisher
            .compactMap { $0.first(where: { $0.option == .market })?.value.value }
            .first()
            .sink { initialSetupCustomFee($0) }
    }
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
