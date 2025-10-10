//
//  TangemAPIKeyProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct TangemAPIKeyProvider {
    @Injected(\.keysManager) private var keysManager: KeysManager

    func getApiKeyHeader() -> Header? {
        let apiKeyValue = getApiKey()

        if apiKeyValue.isEmpty {
            return nil
        }

        return Header(name: TangemAPIHeaders.apiKey.rawValue, value: apiKeyValue)
    }

    private func getApiKey() -> String {
        switch FeatureStorage.instance.tangemAPIType {
        case .prod:
            keysManager.tangemApiKey
        case .dev:
            keysManager.tangemApiKeyDev
        case .stage:
            keysManager.tangemApiKeyStage
        case .mock:
            ""
        }
    }
}

extension TangemAPIKeyProvider {
    struct Header {
        let name: String
        let value: String
    }
}
