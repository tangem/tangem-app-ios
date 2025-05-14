//
//  VisaCustomerCardInfoProviderBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

public struct VisaCustomerCardInfoProviderBuilder {
    private let apiType: VisaAPIType
    private let isMockedAPIEnabled: Bool
    private let isTestnet: Bool
    private let cardId: String

    public init(apiType: VisaAPIType, isMockedAPIEnabled: Bool, isTestnet: Bool, cardId: String) {
        self.apiType = apiType
        self.isMockedAPIEnabled = isMockedAPIEnabled
        self.isTestnet = isTestnet
        self.cardId = cardId
    }

    public func build(
        cardActivationState: VisaCardActivationLocalState,
        refreshTokenSaver: VisaRefreshTokenSaver,
        evmSmartContractInteractor: EVMSmartContractInteractor,
        urlSessionConfiguration: URLSessionConfiguration
    ) -> VisaCustomerCardInfoProvider {
        let authorizationTokensHandler = VisaAuthorizationTokensHandlerBuilder(apiType: apiType, isMockedAPIEnabled: isMockedAPIEnabled)
            .build(
                cardId: cardId,
                cardActivationStatus: cardActivationState,
                refreshTokenSaver: refreshTokenSaver,
                urlSessionConfiguration: urlSessionConfiguration
            )

        return build(
            authorizationTokensHandler: authorizationTokensHandler,
            evmSmartContractInteractor: evmSmartContractInteractor,
            urlSessionConfiguration: urlSessionConfiguration
        )
    }

    public func build(
        authorizationTokensHandler: VisaAuthorizationTokensHandler?,
        evmSmartContractInteractor: EVMSmartContractInteractor,
        urlSessionConfiguration: URLSessionConfiguration
    ) -> VisaCustomerCardInfoProvider {
        var customerInfoManagementService: CustomerInfoManagementService?
        if let authorizationTokensHandler {
            if isMockedAPIEnabled {
                customerInfoManagementService = CustomerInfoManagementServiceMock()
            } else {
                customerInfoManagementService = CommonCustomerInfoManagementService(
                    apiType: apiType,
                    authorizationTokenHandler: authorizationTokensHandler,
                    apiService: .init(
                        provider: MoyaProviderBuilder().buildProvider(configuration: urlSessionConfiguration),
                        decoder: JSONDecoderFactory().makeCIMDecoder()
                    )
                )
            }
        }

        return CommonCustomerCardInfoProvider(
            isTestnet: isTestnet,
            authorizationTokensHandler: authorizationTokensHandler,
            customerInfoManagementService: customerInfoManagementService,
            evmSmartContractInteractor: evmSmartContractInteractor
        )
    }
}
