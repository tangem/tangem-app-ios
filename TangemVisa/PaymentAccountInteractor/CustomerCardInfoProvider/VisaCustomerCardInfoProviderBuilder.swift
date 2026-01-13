//
//  VisaCustomerCardInfoProviderBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation
import TangemNetworkUtils
import TangemPay

public struct VisaCustomerCardInfoProviderBuilder {
    private let apiType: TangemPayAPIType

    public init(apiType: TangemPayAPIType) {
        self.apiType = apiType
    }

    public func build(
        authorizationTokensHandler: VisaAuthorizationTokensHandler?,
        evmSmartContractInteractor: EVMSmartContractInteractor,
        urlSessionConfiguration: URLSessionConfiguration = .visaConfiguration
    ) -> VisaCustomerCardInfoProvider {
        CommonCustomerCardInfoProvider(
            isTestnet: apiType.isTestnet,
            customerService: nil,
            evmSmartContractInteractor: evmSmartContractInteractor
        )
    }
}
