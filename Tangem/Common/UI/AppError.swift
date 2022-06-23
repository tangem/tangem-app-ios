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

    var errorDescription: String? {
        switch self {
        case .serverUnavailable:
            return "common_server_unavailable".localized
        }
    }
}
