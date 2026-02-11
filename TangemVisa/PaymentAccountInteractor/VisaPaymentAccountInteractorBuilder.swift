//
//  VisaPaymentAccountInteractorBuilder.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemNetworkUtils

public struct VisaPaymentAccountInteractorBuilder {
    private let isTestnet: Bool
    private let evmSmartContractInteractor: EVMSmartContractInteractor

    public init(
        isTestnet: Bool,
        evmSmartContractInteractor: EVMSmartContractInteractor,
    ) {
        self.isTestnet = isTestnet
        self.evmSmartContractInteractor = evmSmartContractInteractor
    }

    public func build(
        customerCardInfo: VisaCustomerCardInfo,
        urlSessionConfiguration: URLSessionConfiguration = .visaConfiguration
    ) async throws -> VisaPaymentAccountInteractor {
        VisaLogger.info("Start loading token info")
        let tokenInfoLoader = VisaTokenInfoLoader(
            isTestnet: isTestnet,
            evmSmartContractInteractor: evmSmartContractInteractor
        )
        let visaToken = try await tokenInfoLoader.loadTokenInfo(for: customerCardInfo.paymentAccount)

        VisaLogger.info("Creating Payment account interactor for founded PaymentAccount")
        return CommonPaymentAccountInteractor(
            customerCardInfo: customerCardInfo,
            visaToken: visaToken,
            isTestnet: isTestnet,
            evmSmartContractInteractor: evmSmartContractInteractor
        )
    }
}
