//
//  VisaBuilder+FeatureStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemVisa
import TangemPay

extension VisaCardScanHandlerBuilder {
    init() {
        self = VisaCardScanHandlerBuilder(
            apiType: FeatureStorage.instance.visaAPIType
        )
    }
}

extension VisaAPIServiceBuilder {
    init() {
        self = VisaAPIServiceBuilder(
            apiType: FeatureStorage.instance.visaAPIType
        )
    }
}

extension VisaAuthorizationTokensHandlerBuilder {
    init() {
        self = VisaAuthorizationTokensHandlerBuilder(
            apiType: FeatureStorage.instance.visaAPIType
        )
    }
}

extension VisaCustomerCardInfoProviderBuilder {
    init() {
        self = VisaCustomerCardInfoProviderBuilder(
            apiType: FeatureStorage.instance.visaAPIType
        )
    }
}

extension VisaCardActivationStatusServiceBuilder {
    init() {
        self = VisaCardActivationStatusServiceBuilder(
            apiType: FeatureStorage.instance.visaAPIType
        )
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

extension PaymentAccountCustomerInfoManagementServiceBuilder {
    init() {
        self = PaymentAccountCustomerInfoManagementServiceBuilder(
            apiType: FeatureStorage.instance.visaAPIType,
            bffStaticToken: TangemPayUtilities.getBFFStaticToken()
        )
    }
}

extension PaymentAccountAvailabilityServiceBuilder {
    init() {
        self = PaymentAccountAvailabilityServiceBuilder(
            apiType: FeatureStorage.instance.visaAPIType,
            bffStaticToken: TangemPayUtilities.getBFFStaticToken(),
            paeraCustomerFlagRepository: AppSettings.shared
        )
    }
}

extension PaymentAccountAuthorizationServiceBuilder {
    @Injected(\.paymentAccountAuthorizationTokensRepository)
    private static var paymentAccountAuthorizationTokensRepository: PaymentAccountAuthorizationTokensRepository

    init() {
        self = PaymentAccountAuthorizationServiceBuilder(
            apiType: FeatureStorage.instance.visaAPIType,
            authorizationTokensRepository: Self.paymentAccountAuthorizationTokensRepository,
            bffStaticToken: TangemPayUtilities.getBFFStaticToken()
        )
    }
}
