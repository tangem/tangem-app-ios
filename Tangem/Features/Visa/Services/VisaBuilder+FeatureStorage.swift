//
//  VisaBuilder+FeatureStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemVisa

extension VisaCardScanHandlerBuilder {
    init() {
        self = VisaCardScanHandlerBuilder(
            apiType: FeatureStorage.instance.tangemPayAPIType
        )
    }
}

extension VisaAPIServiceBuilder {
    init() {
        self = VisaAPIServiceBuilder(
            apiType: FeatureStorage.instance.tangemPayAPIType
        )
    }
}

extension VisaAuthorizationTokensHandlerBuilder {
    init() {
        self = VisaAuthorizationTokensHandlerBuilder(
            apiType: FeatureStorage.instance.tangemPayAPIType
        )
    }
}

extension VisaCustomerCardInfoProviderBuilder {
    init() {
        self = VisaCustomerCardInfoProviderBuilder(
            apiType: FeatureStorage.instance.tangemPayAPIType
        )
    }
}

extension VisaCardActivationStatusServiceBuilder {
    init() {
        self = VisaCardActivationStatusServiceBuilder(
            apiType: FeatureStorage.instance.tangemPayAPIType
        )
    }
}

extension VisaPaymentAccountInteractorBuilder {
    init(evmSmartContractInteractor: EVMSmartContractInteractor) {
        self = VisaPaymentAccountInteractorBuilder(
            isTestnet: true,
            evmSmartContractInteractor: evmSmartContractInteractor
        )
    }
}
