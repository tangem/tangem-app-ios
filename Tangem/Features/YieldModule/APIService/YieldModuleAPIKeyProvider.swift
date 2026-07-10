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

    func getApiKeyHeader(for apiType: YieldModuleAPIType) -> HTTPHeader? {
        let apiKeyValue = getApiKey(for: apiType)

        guard !apiKeyValue.isEmpty else {
            return nil
        }

        return HTTPHeader(name: TangemAPIHeaders.apiKey.rawValue, value: apiKeyValue)
    }

    private func getApiKey(for apiType: YieldModuleAPIType) -> String {
        switch apiType {
        case .prod:
            keysManager.yieldModuleApiKey
        case .dev, .stage, .mock:
            keysManager.yieldModuleApiKeyDev
        }
    }
}
