//
//  TangemPayNetworkContractOrderRetryPolicy.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum TangemPayNetworkContractOrderRetryPolicy {
    public static let placeOrderDelays: [TimeInterval] = [1, 2, 4]

    public static func isRetryable(_ error: TangemPayAPIServiceError) -> Bool {
        switch error {
        case .moyaError, .serverError:
            true
        case .unauthorized, .apiError, .decodingError:
            false
        }
    }
}
