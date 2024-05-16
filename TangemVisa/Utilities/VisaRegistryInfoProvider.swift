//
//  VisaRegistryInfoProvider.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct VisaRegistryInfoProvider {
    private let fileName = "visa_config"

    func getRegistryAddress(isTestnet: Bool) throws -> String {
        guard let path = Bundle(for: BundleToken.self).url(forResource: fileName, withExtension: "json") else {
            throw NSError(domain: "Failed to find json file with name: \"\(fileName)\"", code: -9999, userInfo: nil)
        }

        let config = try JSONDecoder().decode(RegistryInfoConfig.self, from: Data(contentsOf: path))
        return isTestnet ? config.testnet.paymentAccountRegistry : config.testnet.paymentAccountRegistry
    }
}

private struct RegistryInfoConfig: Decodable {
    struct Addresses: Decodable {
        let paymentAccountRegistry: String
        let bridgeProcessor: String
    }

    let testnet: Addresses
    let mainnet: Addresses
}

private class BundleToken {}
