//
//  DestinationViewModelValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol DestinationViewModelValidator {
    func validate(destination: String) throws
    func canEmbedAdditionalField(into address: String) -> Bool
}
