//
//  VisaPaymentAccountInteractorBuilder.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

public struct VisaPaymentAccountInteractorBuilder {
    private let isTestnet: Bool
    private let evmSmartContractInteractor: EVMSmartContractInteractor
    private let urlSessionConfiguration: URLSessionConfiguration
    private let isMockedAPIEnabled: Bool
    private let logger: InternalLogger = .init()

    public init(
        isTestnet: Bool,
        evmSmartContractInteractor: EVMSmartContractInteractor,
        urlSessionConfiguration: URLSessionConfiguration,
        isMockedAPIEnabled: Bool
    ) {
        self.isTestnet = isTestnet
        self.evmSmartContractInteractor = evmSmartContractInteractor
        self.urlSessionConfiguration = urlSessionConfiguration
        self.isMockedAPIEnabled = isMockedAPIEnabled
    }

    public func build(customerCardInfo: VisaCustomerCardInfo) async throws -> VisaPaymentAccountInteractor {
        log("Start loading token info")
        let tokenInfoLoader = VisaTokenInfoLoader(
            isTestnet: isTestnet,
            evmSmartContractInteractor: evmSmartContractInteractor,
            logger: logger
        )
        let visaToken = try await tokenInfoLoader.loadTokenInfo(for: customerCardInfo.paymentAccount)

        log("Creating Bridge interactor for founded PaymentAccount")
        return CommonPaymentAccountInteractor(
            customerCardInfo: customerCardInfo,
            visaToken: visaToken,
            isTestnet: isTestnet,
            evmSmartContractInteractor: evmSmartContractInteractor,
            logger: logger
        )
    }

    private func log<T>(_ message: @autoclosure () -> T) {
        logger.debug(subsystem: .paymentAccountInteractorBuilder, message())
    }
}

public extension VisaPaymentAccountInteractorBuilder {
    enum VisaBridgeInteractorBuilderError: LocalizedError {
        case failedToFindPaymentAccount
        case failedToLoadTokenInfo(error: LocalizedError)

        public var errorDescription: String? {
            switch self {
            case .failedToFindPaymentAccount:
                return "Failed to find payment account"
            case .failedToLoadTokenInfo(let error):
                return "Failed to load token info: \(error.errorDescription ?? "unknown")"
            }
        }
    }
}
