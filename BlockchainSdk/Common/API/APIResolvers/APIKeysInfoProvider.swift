//
//  APIKeysInfoProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

struct APIKeysInfoProvider {
    let blockchain: Blockchain
    let keysConfig: BlockchainSdkKeysConfig

    func apiKeys(for providerType: NetworkProviderType?) -> APIHeaderKeyInfo? {
        switch providerType {
        case .nowNodes:
            return NowNodesAPIKeysInfoProvider(apiKey: keysConfig.nowNodesApiKey)
                .apiKeys(for: blockchain)
        case .arkhiaHedera:
            return .init(
                headerName: Constants.xApiKeyHeaderName,
                headerValue: keysConfig.hederaArkhiaApiKey
            )
        case .ton:
            return .init(
                headerName: Constants.xApiKeyHeaderName,
                headerValue: keysConfig.tonCenterApiKeys.getApiKey(for: blockchain.isTestnet)
            )
        case .tron:
            return .init(
                headerName: "TRON-PRO-API-KEY",
                headerValue: keysConfig.tronGridApiKey
            )
        case .tangemChia:
            return .init(
                headerName: Constants.xApiKeyHeaderName,
                headerValue: keysConfig.chiaTangemApiKeys.mainnetApiKey
            )
        case .tangemChia3:
            return .init(
                headerName: Constants.xApiKeyHeaderName,
                headerValue: keysConfig.chiaTangemApiKeys.mainnetApiKey
            )
        case .fireAcademy:
            return .init(
                headerName: Constants.xApiKeyHeaderName,
                headerValue: keysConfig.fireAcademyApiKeys.getApiKey(for: blockchain.isTestnet)
            )
        case .onfinality:
            return .init(
                headerName: Constants.onfinalityApiKeyHeaderName,
                headerValue: keysConfig.bittensorOnfinalityKey
            )
        case .koinosPro:
            return .init(
                headerName: "apikey",
                headerValue: keysConfig.koinosProApiKey
            )
        case .tangemAlephium:
            return .init(
                headerName: "x-api-key",
                headerValue: keysConfig.tangemAlephiumApiKey
            )
        case .public, .quickNode, .getBlock, .blockchair, .blockcypher, .infura, .adalite, .tangemRosetta, .solana, .kaspa, .dwellir, .none:
            return nil
        }
    }
}
