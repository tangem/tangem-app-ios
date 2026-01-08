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
        let apiKeyValue = getApiKey()

        guard !apiKeyValue.isEmpty else {
            return nil
        }

        return HTTPHeader(name: TangemAPIHeaders.apiKey.rawValue, value: apiKeyValue)
    }

    private func getApiKey() -> String {
        switch FeatureStorage.instance.gaslessTransactionsAPIType {
        case .prod:
            keysManager.gaslessTxApiKey
        case .dev, .stage:
            keysManager.gaslessTxApiKeyDev
        }
    }
}
