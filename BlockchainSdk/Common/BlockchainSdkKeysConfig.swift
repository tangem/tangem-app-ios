//
//  BlockchainSdkKeysConfig.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

public struct BlockchainSdkKeysConfig {
    let blockchairApiKeys: [String]
    let blockcypherTokens: [String]
    let infuraProjectId: String
    let nowNodesApiKey: String
    let getBlockCredentials: GetBlockCredentials
    let kaspaSecondaryApiUrl: String?
    let tronGridApiKey: String
    let hederaArkhiaApiKey: String
    let etherscanApiKey: String
    let koinosProApiKey: String
    let tonCenterApiKeys: TonCenterApiKeys
    let fireAcademyApiKeys: FireAcademyApiKeys
    let chiaTangemApiKeys: ChiaTangemApiKeys
    let quickNodeSolanaCredentials: QuickNodeCredentials
    let quickNodeBscCredentials: QuickNodeCredentials
    let quickNodePlasmaCredentials: QuickNodeCredentials
    let bittensorDwellirKey: String
    let dwellirApiKey: String
    let bittensorOnfinalityKey: String
    let tangemAlephiumApiKey: String
    let blinkApiKey: String
    let tatumApiKey: String
    let yieldModuleApiKey: String
    let gaslessTxApiKey: String

    public init(
        blockchairApiKeys: [String],
        blockcypherTokens: [String],
        infuraProjectId: String,
        nowNodesApiKey: String,
        getBlockCredentials: GetBlockCredentials,
        kaspaSecondaryApiUrl: String?,
        tronGridApiKey: String,
        hederaArkhiaApiKey: String,
        etherscanApiKey: String,
        koinosProApiKey: String,
        tonCenterApiKeys: TonCenterApiKeys,
        fireAcademyApiKeys: FireAcademyApiKeys,
        chiaTangemApiKeys: ChiaTangemApiKeys,
        quickNodeSolanaCredentials: QuickNodeCredentials,
        quickNodeBscCredentials: QuickNodeCredentials,
        quickNodePlasmaCredentials: QuickNodeCredentials,
        bittensorDwellirKey: String,
        dwellirApiKey: String,
        bittensorOnfinalityKey: String,
        tangemAlephiumApiKey: String,
        blinkApiKey: String,
        tatumApiKey: String,
        yieldModuleApiKey: String,
        gaslessTxApiKey: String
    ) {
        self.blockchairApiKeys = blockchairApiKeys
        self.blockcypherTokens = blockcypherTokens
        self.infuraProjectId = infuraProjectId
        self.nowNodesApiKey = nowNodesApiKey
        self.getBlockCredentials = getBlockCredentials
        self.kaspaSecondaryApiUrl = kaspaSecondaryApiUrl
        self.tronGridApiKey = tronGridApiKey
        self.hederaArkhiaApiKey = hederaArkhiaApiKey
        self.etherscanApiKey = etherscanApiKey
        self.koinosProApiKey = koinosProApiKey
        self.tonCenterApiKeys = tonCenterApiKeys
        self.fireAcademyApiKeys = fireAcademyApiKeys
        self.chiaTangemApiKeys = chiaTangemApiKeys
        self.quickNodeSolanaCredentials = quickNodeSolanaCredentials
        self.quickNodeBscCredentials = quickNodeBscCredentials
        self.quickNodePlasmaCredentials = quickNodePlasmaCredentials
        self.bittensorDwellirKey = bittensorDwellirKey
        self.dwellirApiKey = dwellirApiKey
        self.bittensorOnfinalityKey = bittensorOnfinalityKey
        self.tangemAlephiumApiKey = tangemAlephiumApiKey
        self.blinkApiKey = blinkApiKey
        self.tatumApiKey = tatumApiKey
        self.yieldModuleApiKey = yieldModuleApiKey
        self.gaslessTxApiKey = gaslessTxApiKey
    }
}

public extension BlockchainSdkKeysConfig {
    struct QuickNodeCredentials {
        let apiKey: String
        let subdomain: String

        public init(apiKey: String, subdomain: String) {
            self.apiKey = apiKey
            self.subdomain = subdomain
        }
    }

    struct TonCenterApiKeys {
        let mainnetApiKey: String
        let testnetApiKey: String

        public init(mainnetApiKey: String, testnetApiKey: String) {
            self.mainnetApiKey = mainnetApiKey
            self.testnetApiKey = testnetApiKey
        }

        func getApiKey(for testnet: Bool) -> String {
            return testnet ? testnetApiKey : mainnetApiKey
        }
    }

    struct FireAcademyApiKeys {
        let mainnetApiKey: String
        let testnetApiKey: String

        public init(mainnetApiKey: String, testnetApiKey: String) {
            self.mainnetApiKey = mainnetApiKey
            self.testnetApiKey = testnetApiKey
        }

        func getApiKey(for testnet: Bool) -> String {
            return testnet ? testnetApiKey : mainnetApiKey
        }
    }

    struct ChiaTangemApiKeys {
        let mainnetApiKey: String

        public init(mainnetApiKey: String) {
            self.mainnetApiKey = mainnetApiKey
        }
    }

    struct GetBlockCredentials {
        let credentials: [Credential]

        public init(credentials: [Credential]) {
            self.credentials = credentials
        }
    }
}

public extension BlockchainSdkKeysConfig.GetBlockCredentials {
    struct Credential {
        let blockchain: Blockchain
        let type: TypeValue
        let value: String

        public init(blockchain: Blockchain, type: TypeValue, key: String) {
            self.blockchain = blockchain
            self.type = type
            value = key
        }
    }

    enum TypeValue: String, CaseIterable {
        case blockBookRest
        case rest
        case jsonRpc
        case rosetta
    }
}

extension BlockchainSdkKeysConfig.GetBlockCredentials {
    func credential(for blockchain: Blockchain, type: TypeValue) -> String {
        let credential = credentials.first { $0.blockchain.codingKey == blockchain.codingKey && $0.type == type }
        return credential?.value ?? ""
    }

    func credentials(type: TypeValue) -> [Blockchain: String] {
        credentials
            .filter { $0.type == type }
            .reduce(into: [:]) { $0[$1.blockchain] = $1.value }
    }
}
