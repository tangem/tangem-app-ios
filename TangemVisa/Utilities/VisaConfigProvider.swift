//
//  VisaConfigProvider.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class VisaConfigProvider {
    private static var instance: VisaConfigProvider?

    private let fileName = "visa_config"
    private let config: VisaConfig

    private init() throws {
        guard let path = Bundle(for: Self.self).url(forResource: fileName, withExtension: "json") else {
            throw NSError(domain: "Failed to find json file with name: \"\(fileName)\"", code: -9999, userInfo: nil)
        }

        config = try JSONDecoder().decode(VisaConfig.self, from: Data(contentsOf: path))
    }

    static func shared() throws -> VisaConfigProvider {
        guard let instance else {
            let instance = try VisaConfigProvider()
            Self.instance = instance
            return instance
        }

        return instance
    }

    func getRegistryAddress(isTestnet: Bool) -> String {
        return isTestnet ? config.testnet.paymentAccountRegistry : config.mainnet.paymentAccountRegistry
    }

    func getTxHistoryAPIAdditionalHeaders() -> [String: String] {
        config.txHistoryAPIAdditionalHeaders
    }

    func getRSAPublicKey(apiType: VisaAPIType) -> String {
        switch apiType {
        case .prod:
            return config.rsaPublicKey.prod
        case .stage, .dev:
            return config.rsaPublicKey.dev
        }
    }
}

private struct VisaConfig: Decodable {
    struct Addresses: Decodable {
        let paymentAccountRegistry: String
        let bridgeProcessor: String
    }

    struct RSAPublicKeys: Decodable {
        let prod: String
        let dev: String
    }

    let testnet: Addresses
    let mainnet: Addresses
    let txHistoryAPIAdditionalHeaders: [String: String]
    let rsaPublicKey: RSAPublicKeys
}
