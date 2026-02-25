//
//  SendFeeCurrencyProviderDataBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol SendFeeCurrencyProviderDataBuilder {
    func makeFeeCurrencyData() throws -> FeeCurrencyNavigatingDismissOption
}

enum SendFeeCurrencyProviderDataBuilderError: LocalizedError {
    case notSupported

    var errorDescription: String? {
        switch self {
        case .notSupported: "Not supported"
        }
    }
}
