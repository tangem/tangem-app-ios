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
    private let evmSmartContractInteractor: EVMSmartContractInteractor

    public init(evmSmartContractInteractor: EVMSmartContractInteractor) {
        self.evmSmartContractInteractor = evmSmartContractInteractor
    }

    public func build(for cardAddress: String) async throws -> VisaBridgeInteractor {
        var paymentAccount: String?
        for bridgeAddress in VisaUtilities().TangemBridgeProcessorAddresses {
            let request = VisaSmartContractRequest(
                contractAddress: bridgeAddress,
                method: GetPaymentAccountMethod(cardWalletAddress: cardAddress)
            )

            do {
                let response = try await evmSmartContractInteractor.ethCall(request: request).async()
                let addressParser = try AddressParser().parseAddressResponse(response)
                paymentAccount = addressParser
                break
            } catch {
                print("Failed to get paymentAccount. Reason: \(error)")
            }
        }

        guard let paymentAccount else {
            throw VisaBridgeInteractorBuilderError.failedToFindPaymentAccount
        }

        return CommonBridgeInteractor(evmSmartContractInteractor: evmSmartContractInteractor, paymentAccount: paymentAccount)
    }
}

public extension VisaBridgeInteractorBuilder {
    enum VisaBridgeInteractorBuilderError: LocalizedError {
        case failedToFindPaymentAccount

        public var errorDescription: String? {
            switch self {
            case .failedToFindPaymentAccount:
                return "Failed to find payment account for card address"
            }
        }
    }
}
