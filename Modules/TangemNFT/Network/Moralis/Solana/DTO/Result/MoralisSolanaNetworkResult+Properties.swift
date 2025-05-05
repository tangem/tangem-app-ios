//
//  MoralisSolanaNetworkResult+Properties.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

extension MoralisSolanaNetworkResult {
    struct Properties: Decodable {
        let files: [File]?
        let category: String?
        let creators: [SimpleCreator]?
    }
}

extension MoralisSolanaNetworkResult.Properties {
    struct SimpleCreator: Decodable {
        let address: String?
        let share: Int?
    }

    struct File: Decodable {
        let uri: String?
        let type: String?
    }
}
