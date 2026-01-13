//
//  VisaBuilder+FeatureStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemPay
import TangemVisa

extension VisaCardScanHandlerBuilder {
    init() {
        self = VisaCardScanHandlerBuilder(apiType: FeatureStorage.instance.visaAPIType)
    }
}

extension VisaAPIServiceBuilder {
    init() {
        self = VisaAPIServiceBuilder(apiType: FeatureStorage.instance.visaAPIType)
    }
}

extension VisaAuthorizationTokensHandlerBuilder {
    init() {
        self = VisaAuthorizationTokensHandlerBuilder(apiType: FeatureStorage.instance.visaAPIType)
    }
}

extension VisaCustomerCardInfoProviderBuilder {
    init() {
        self = VisaCustomerCardInfoProviderBuilder(apiType: FeatureStorage.instance.visaAPIType)
    }
}

extension VisaCardActivationStatusServiceBuilder {
    init() {
        self = VisaCardActivationStatusServiceBuilder(apiType: FeatureStorage.instance.visaAPIType)
    }
}

extension VisaPaymentAccountInteractorBuilder {
    init(evmSmartContractInteractor: EVMSmartContractInteractor) {
        self = VisaPaymentAccountInteractorBuilder(
            isTestnet: FeatureStorage.instance.visaAPIType.isTestnet,
            evmSmartContractInteractor: evmSmartContractInteractor
        )
    }
}

extension TangemPayAvailabilityServiceBuilder {
    @Injected(\.keysManager)
    private static var keysManager: KeysManager

    init() {
        self = TangemPayAvailabilityServiceBuilder(
            apiType: FeatureStorage.instance.visaAPIType,
            bffStaticToken: Self.keysManager.bffStaticToken
        )
    }
}

extension TangemPayAuthorizationServiceBuilder {
    @Injected(\.tangemPayAuthorizationTokensRepository)
    private static var tangemPayAuthorizationTokensRepository: TangemPayAuthorizationTokensRepository

    @Injected(\.keysManager)
    private static var keysManager: KeysManager

    init() {
        self = TangemPayAuthorizationServiceBuilder(
            apiType: FeatureStorage.instance.visaAPIType,
            authorizationTokensRepository: Self.tangemPayAuthorizationTokensRepository,
            bffStaticToken: Self.keysManager.bffStaticToken
        )
    }
}

extension TangemPayCustomerInfoManagementServiceBuilder {
    init() {
        self = TangemPayCustomerInfoManagementServiceBuilder(
            apiType: FeatureStorage.instance.visaAPIType
        )
    }
}
