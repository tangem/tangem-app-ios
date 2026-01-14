//
//  GaslessTransactionsAPIKeyProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Alamofire

struct GaslessTransactionsAPIKeyProvider {
    @Injected(\.keysManager) private var keysManager: KeysManager

    func getApiKeyHeader() -> HTTPHeader? {
        let headerValue = headerValue()

        guard !headerValue.isEmpty else {
            return nil
        }

        return HTTPHeader(name: TangemAPIHeaders.authorization.rawValue, value: headerValue)
    }

    private func headerValue() -> String {
        let key = switch FeatureStorage.instance.gaslessTransactionsAPIType {
        case .prod:
            keysManager.gaslessTxApiKey
        case .dev, .stage:
            keysManager.gaslessTxApiKeyDev
        }

        return TangemAPIHeadersValues.bearerPrefix + key
    }
}
