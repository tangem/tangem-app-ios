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
            apiType: FeatureStorage.instance.visaAPIType,
            isMockedAPIEnabled: FeatureStorage.instance.isVisaAPIMocksEnabled
        )
    }
}

extension VisaAPIServiceBuilder {
    init() {
        self = VisaAPIServiceBuilder(
            apiType: FeatureStorage.instance.visaAPIType,
            isMockedAPIEnabled: FeatureStorage.instance.isVisaAPIMocksEnabled
        )
    }
}

extension VisaAuthorizationTokensHandlerBuilder {
    init() {
        self = VisaAuthorizationTokensHandlerBuilder(
            apiType: FeatureStorage.instance.visaAPIType,
            isMockedAPIEnabled: FeatureStorage.instance.isVisaAPIMocksEnabled
        )
    }
}

extension VisaCustomerCardInfoProviderBuilder {
    init() {
        self = VisaCustomerCardInfoProviderBuilder(
            apiType: FeatureStorage.instance.visaAPIType,
            isMockedAPIEnabled: FeatureStorage.instance.isVisaAPIMocksEnabled
        )
    }
}

extension VisaCardActivationStatusServiceBuilder {
    init() {
        self = VisaCardActivationStatusServiceBuilder(
            apiType: FeatureStorage.instance.visaAPIType,
            isMockedAPIEnabled: FeatureStorage.instance.isVisaAPIMocksEnabled
        )
    }
}

extension VisaPaymentAccountInteractorBuilder {
    init(evmSmartContractInteractor: EVMSmartContractInteractor) {
        self = VisaPaymentAccountInteractorBuilder(
            isTestnet: FeatureStorage.instance.visaAPIType.isTestnet,
            evmSmartContractInteractor: evmSmartContractInteractor,
            isMockedAPIEnabled: FeatureStorage.instance.isVisaAPIMocksEnabled
        )
    }
}
