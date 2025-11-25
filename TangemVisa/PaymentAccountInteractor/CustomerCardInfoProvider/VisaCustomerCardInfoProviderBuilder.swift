//
//  VisaCustomerCardInfoProviderBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemNetworkUtils

public struct VisaCustomerCardInfoProviderBuilder {
    private let apiType: VisaAPIType
    private let isMockedAPIEnabled: Bool

    public init(apiType: VisaAPIType, isMockedAPIEnabled: Bool) {
        self.apiType = apiType
        self.isMockedAPIEnabled = isMockedAPIEnabled
    }

    public func build(
        authorizationTokensHandler: VisaAuthorizationTokensHandler?,
        evmSmartContractInteractor: EVMSmartContractInteractor,
        urlSessionConfiguration: URLSessionConfiguration = .visaConfiguration
    ) -> VisaCustomerCardInfoProvider {
        var customerInfoManagementService: CustomerInfoManagementService?
        if let authorizationTokensHandler {
            customerInfoManagementService = buildCustomerInfoManagementService(
                authorizationTokensHandler: authorizationTokensHandler,
                urlSessionConfiguration: urlSessionConfiguration,
                authorizeWithCustomerWallet: {
                    guard let tokens = authorizationTokensHandler.authorizationTokens else {
                        throw VisaAuthorizationTokensHandlerError.authorizationTokensNotFound
                    }
                    return tokens
                }
            )
        }

        return CommonCustomerCardInfoProvider(
            isTestnet: apiType.isTestnet,
            customerInfoManagementService: customerInfoManagementService,
            evmSmartContractInteractor: evmSmartContractInteractor
        )
    }

    public func buildCustomerInfoManagementService(
        authorizationTokensHandler: VisaAuthorizationTokensHandler,
        urlSessionConfiguration: URLSessionConfiguration = .visaConfiguration,
        authorizeWithCustomerWallet: @escaping () async throws -> VisaAuthorizationTokens
    ) -> CustomerInfoManagementService {
        if isMockedAPIEnabled {
            return CustomerInfoManagementServiceMock()
        } else {
            return CommonCustomerInfoManagementService(
                apiType: apiType,
                authorizationTokenHandler: authorizationTokensHandler,
                apiService: .init(
                    provider: TangemPayProviderBuilder().buildProvider(
                        configuration: urlSessionConfiguration,
                        authorizationTokensHandler: authorizationTokensHandler
                    ),
                    decoder: JSONDecoderFactory().makeCIMDecoder()
                ),
                authorizeWithCustomerWallet: authorizeWithCustomerWallet
            )
        }
    }
}
