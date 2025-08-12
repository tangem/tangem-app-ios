//
//  TangemApiAuthorizationPlugin.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Moya

struct TangemApiAuthorizationPlugin: PluginType {
    @Injected(\.keysManager) private var keysManager: KeysManager
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var request = request

        let apiKey = keysManager.tangemApiKey
        if !apiKey.isEmpty {
            request.headers.add(name: "api-key", value: apiKey)
        }

        if let authDataFromSelectedOrAnyModel = userWalletRepository.selectedModel?.tangemApiAuthData ??
            userWalletRepository.models.first(where: { $0.tangemApiAuthData != nil })?.tangemApiAuthData {
            request.headers.add(name: "card_id", value: authDataFromSelectedOrAnyModel.cardId)
            request.headers.add(name: "card_public_key", value: authDataFromSelectedOrAnyModel.cardPublicKey.hexString)
        }

        return request
    }
}

struct TangemApiAuthorizationData {
    let cardId: String
    let cardPublicKey: Data
}
