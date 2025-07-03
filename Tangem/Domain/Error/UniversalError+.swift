//
//  UniversalError+.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization

extension UniversalError {
    var localizedDescription: String {
        if let errorDescription {
            return errorDescription
        }

        return Localization.universalError(errorCode)
    }
}

extension UniversalErrorWrapper {
    var localizedDescription: String {
        if let errorDescription {
            return errorDescription
        }

        return Localization.universalError(errorCode)
    }
}

extension Error {
    var localizedDescription: String {
        if let universalDescription = (self as? UniversalError)?.localizedDescription {
            return universalDescription
        }

        if let localizedDescription = (self as? LocalizedError)?.errorDescription {
            return localizedDescription
        }

        return Localization.universalError("\(self)")
    }
}
