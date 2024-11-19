//
//  JoystreamExternalLinkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct JoystreamExternalLinkProvider: ExternalLinkProvider {
    var testnetFaucetURL: URL? { nil }

    private let explorerBaseURL = "https://joystream.subscan.io"

    func url(transaction hash: String) -> URL? {
        return URL(string: "\(explorerBaseURL)/extrinsic/\(hash)")
    }

    func url(address: String, contractAddress: String?) -> URL? {
        return URL(string: "\(explorerBaseURL)/account/\(address)")
    }
}
