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
        CommonCustomerCardInfoProvider(
            isTestnet: apiType.isTestnet,
            customerInfoManagementService: nil,
            evmSmartContractInteractor: evmSmartContractInteractor
        )
    }
}

public struct TangemPayCustomerInfoManagementServiceBuilder {
    private let apiType: VisaAPIType

    public init(apiType: VisaAPIType) {
        self.apiType = apiType
    }
}

public extension TangemPayCustomerInfoManagementServiceBuilder {
    func buildCustomerInfoManagementService(
        authorizationTokensHandler: TangemPayAuthorizationTokensHandler,
        urlSessionConfiguration: URLSessionConfiguration = .visaConfiguration,
        authorizeWithCustomerWallet: @escaping () async throws -> TangemPayAuthorizationTokens
    ) -> CustomerInfoManagementService {
        CommonCustomerInfoManagementService(
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
