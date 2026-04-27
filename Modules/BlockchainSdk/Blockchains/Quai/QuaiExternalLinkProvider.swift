//
//  QuaiExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct QuaiExternalLinkProvider {
    private let explorerURL: URL?

    init(isTestnet: Bool) {
        explorerURL = isTestnet ? Constants.testnetExplorerURL : Constants.mainnetExplorerURL
    }
}

extension QuaiExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? {
        Constants.testnetFaucetURL
    }

    func url(transaction hash: String) -> URL? {
        explorerURL?.appending(path: "tx").appending(path: hash)
    }

    func url(address: String, contractAddress: String?) -> URL? {
        explorerURL?.appending(path: "address").appending(path: address)
    }
}

private extension QuaiExternalLinkProvider {
    enum Constants {
        static let mainnetExplorerURL = URL(string: "https://quaiscan.io/")
        static let testnetExplorerURL = URL(string: "https://orchard.quaiscan.io/")
        static let testnetFaucetURL = URL(string: "https://orchard.faucet.quai.network/")
    }
}
