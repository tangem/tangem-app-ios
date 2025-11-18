//
//  YieldModuleAPIKeyProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Alamofire

struct YieldModuleAPIKeyProvider {
    @Injected(\.keysManager) private var keysManager: KeysManager

    func getApiKeyHeader() -> HTTPHeader? {
        let apiKeyValue = getApiKey()

        guard !apiKeyValue.isEmpty else {
            return nil
        }

        return HTTPHeader(name: TangemAPIHeaders.apiKey.rawValue, value: apiKeyValue)
    }

    private func getApiKey() -> String {
        switch FeatureStorage.instance.yieldModuleAPIType {
        case .prod:
            keysManager.yieldModuleApiKey
        case .dev, .stage:
            keysManager.yieldModuleApiKeyDev
        }
    }
}
