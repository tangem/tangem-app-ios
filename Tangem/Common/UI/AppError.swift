//
//  AppError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

enum AppError: Error, LocalizedError {
    case serverUnavailable
    case wrongCardWasTapped

    var errorDescription: String? {
        switch self {
        case .serverUnavailable:
            return L10n.commonServerUnavailable
        case .wrongCardWasTapped:
            return L10n.errorWrongWalletTapped
        }
    }
}
