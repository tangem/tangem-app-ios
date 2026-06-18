//
//  CommonCryptoAddressAdditionalFieldProcessor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

struct CommonCryptoAddressAdditionalFieldProcessor {
    private let additionalFieldType: SendDestinationAdditionalFieldType?
    private let parametersBuilder: TransactionParamsBuilder

    init(blockchain: BSDKBlockchain) {
        additionalFieldType = .type(for: blockchain)
        parametersBuilder = .init(blockchain: blockchain)
    }
}

// MARK: - CryptoAddressAdditionalFieldProcessor

extension CommonCryptoAddressAdditionalFieldProcessor: CryptoAddressAdditionalFieldProcessor {
    var additionalFieldTypePublisher: AnyPublisher<SendDestinationAdditionalFieldType?, Never> {
        .just(output: additionalFieldType)
    }

    func makeAdditionalField(value: String) throws -> SendDestinationAdditionalField {
        guard let additionalFieldType else {
            return .notSupported
        }

        guard !value.isEmpty else {
            return .empty(type: additionalFieldType)
        }

        do {
            let params = try parametersBuilder.transactionParameters(value: value)
            return .filled(type: additionalFieldType, value: value, params: params)
        } catch TransactionParamsBuilderError.extraIdNotSupported {
            // The blockchain advertises a memo type but can't build params — a wiring error, not user input.
            assertionFailure("Additional field shown for a blockchain that doesn't support transaction parameters")
            return .notSupported
        }
    }
}
