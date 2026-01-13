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

extension TangemPayAPIServiceBuilder {
    @Injected(\.keysManager)
    private static var keysManager: KeysManager

    @Injected(\.tangemPayAuthorizationTokensRepository)
    private static var tangemPayAuthorizationTokensRepository: TangemPayAuthorizationTokensRepository

    init() {
        self = TangemPayAPIServiceBuilder(
            apiType: FeatureStorage.instance.visaAPIType,
            bffStaticToken: Self.keysManager.bffStaticToken,
            authorizationTokensRepository: Self.tangemPayAuthorizationTokensRepository
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
