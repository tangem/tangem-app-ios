//
//  VisaCardActivationInput.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct VisaCardActivationInput: Equatable, Codable {
    public let cardId: String
    public let cardPublicKey: Data

    public init(cardId: String, cardPublicKey: Data) {
        self.cardId = cardId
        self.cardPublicKey = cardPublicKey
    }
}
