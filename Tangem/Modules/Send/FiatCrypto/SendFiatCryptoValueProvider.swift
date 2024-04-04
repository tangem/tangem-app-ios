//
//  SendFiatCryptoValueProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol SendFiatCryptoValueProvider: AnyObject {
    var formattedAmount: String? { get }
    var formattedAmountAlternative: String? { get }

    var formattedAmountPublisher: AnyPublisher<String?, Never> { get }
    var formattedAmountAlternativePublisher: AnyPublisher<String?, Never> { get }
}
