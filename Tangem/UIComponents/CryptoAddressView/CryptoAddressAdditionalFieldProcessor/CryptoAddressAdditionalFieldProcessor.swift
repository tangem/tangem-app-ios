//
//  CryptoAddressAdditionalFieldProcessor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk

protocol CryptoAddressAdditionalFieldProcessor {
    var additionalFieldTypePublisher: AnyPublisher<SendDestinationAdditionalFieldType?, Never> { get }

    func makeAdditionalField(value: String) throws -> SendDestinationAdditionalField
}
