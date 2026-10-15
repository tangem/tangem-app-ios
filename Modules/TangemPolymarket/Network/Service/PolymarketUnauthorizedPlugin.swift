//
//  PolymarketUnauthorizedPlugin.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct PolymarketUnauthorizedPlugin: PluginType {
    let walletId: String
    weak var observer: PolymarketUnauthorizedObserving?

    func didReceive(_ result: Result<Response, MoyaError>, target: any TargetType) {
        let statusCode: Int? = switch result {
        case .success(let response): response.statusCode
        case .failure(let error): error.response?.statusCode
        }

        guard statusCode == Constants.unauthorizedStatusCode else { return }

        PolymarketLogger.warning("The backend rejected the wallet's authorization")
        observer?.backendRejectedAuthorization(walletId: walletId)
    }
}

// MARK: - Constants

private extension PolymarketUnauthorizedPlugin {
    enum Constants {
        static let unauthorizedStatusCode = 401
    }
}
