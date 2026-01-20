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

    public init(apiType: VisaAPIType) {
        self.apiType = apiType
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
