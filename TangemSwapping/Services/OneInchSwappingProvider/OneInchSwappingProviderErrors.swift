//
//  OneInchSwappingProviderErrors.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

extension OneInchSwappingProvider {
    enum Errors: Error {
        case noData
        case incorrectDataFormat
    }
}
