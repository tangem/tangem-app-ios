//
//  VisaBridgeInteractorBuilder.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

public struct VisaBridgeInteractorBuilder {
    public init() {}

    public func buildInteractor(
        for cardAddress: String,
        using smartContractInteractor: EVMSmartContractInteractor,
        logger: VisaLogger
    ) async throws -> VisaBridgeInteractor {
        let logger = InternalLogger(logger: logger)
        var paymentAccount: String?
        logger.debug(topic: .bridgeInteractorBuilder, "Start searching PaymentAccount for card with address: \(cardAddress)")
        for bridgeAddress in VisaUtilities().TangemBridgeProcessorAddresses {
            logger.debug(topic: .bridgeInteractorBuilder, "Requesting PaymentAccount from bridge with address \(bridgeAddress)")
            let request = VisaSmartContractRequest(
                contractAddress: bridgeAddress,
                method: GetPaymentAccountMethod(cardWalletAddress: cardAddress)
            )

            do {
                let response = try await smartContractInteractor.ethCall(request: request).async()
                paymentAccount = try AddressParser().parseAddressResponse(response)
                logger.debug(topic: .bridgeInteractorBuilder, "PaymentAccount founded: \(paymentAccount ?? .unknown)")
                break
            } catch {
                logger.debug(topic: .bridgeInteractorBuilder, "Failed to receive PaymentAccount. Reason: \(error)")
            }
        }

        guard let paymentAccount else {
            logger.debug(topic: .bridgeInteractorBuilder, "No payment account for card address: \(cardAddress)")
            throw VisaBridgeInteractorBuilderError.failedToFindPaymentAccount
        }

        logger.debug(topic: .bridgeInteractorBuilder, "Creating Bridge interactor for founded PaymentAccount")
        return DefaultBridgeInteractor(
            smartContractInteractor: smartContractInteractor,
            paymentAccount: paymentAccount,
            logger: logger
        )
    }
}

public extension VisaBridgeInteractorBuilder {
    enum VisaBridgeInteractorBuilderError: Error {
        case failedToFindPaymentAccount
    }
}
