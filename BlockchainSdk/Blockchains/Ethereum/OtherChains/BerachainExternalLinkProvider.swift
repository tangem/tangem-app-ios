//
//  BerachainExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

struct BerachainExternalLinkProvider: ExternalLinkProvider {
    let testnetFaucetURL: URL? = URL(string: "https://bepolia.faucet.berachain.com/")
    private let explorerURL: String

    init(isTestnet: Bool) {
        explorerURL = isTestnet ? "https://testnet.berascan.com" : "https://berascan.com"
    }

    func url(address: String, contractAddress: String?) -> URL? {
        URL(string: "\(explorerURL)/address/\(address)")
    }

    func url(transaction hash: String) -> URL? {
        URL(string: "\(explorerURL)/tx/\(hash)")
    }
}
