//
//  KeysParser.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

class KeysParser {
    let keys: CommonKeysManager.Keys

    init() throws {
        let keysFileName = "config"
        let keys = try JsonUtils.readBundleFile(with: keysFileName, type: CommonKeysManager.Keys.self)

        if keys.blockchairApiKey.isEmpty ||
            keys.blockcypherTokens.isEmpty ||
            keys.infuraProjectId.isEmpty {
            throw NSError(domain: "Empty keys in config file", code: -9998, userInfo: nil)
        }

        if keys.blockcypherTokens.first(where: { $0.isEmpty }) != nil {
            throw NSError(domain: "One of blockcypher tokens is empty", code: -10001, userInfo: nil)
        }

        self.keys = keys
    }
}
