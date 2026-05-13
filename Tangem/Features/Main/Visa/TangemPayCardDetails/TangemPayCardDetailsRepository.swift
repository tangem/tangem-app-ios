//
//  TangemPayCardDetailsRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemPay

protocol TangemPayCardDetailsRepository: AnyObject {
    var lastFourDigits: String { get }
    var cardNamePublisher: AnyPublisher<String, Never> { get }

    func updateCardDisplayName(_ name: String) async throws
    func revealRequest() async throws -> TangemPayCardDetailsData
}
