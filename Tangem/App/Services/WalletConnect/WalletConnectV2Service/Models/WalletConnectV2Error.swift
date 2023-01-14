//
//  WalletConnectV2Error.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import BlockchainSdk

enum WalletConnectV2Error: Error {
    case unsupportedBlockchains([String])
    case sessionForTopicNotFound
    case missingBlockchains([String])

    case unknown(String)

    var code: Int {
        switch self {
        case .unsupportedBlockchains: return 8001
        case .sessionForTopicNotFound: return 8002
        case .missingBlockchains: return 8003

        case .unknown: return 8999
        }
    }

    init?(from string: String) {
        switch string {
        case "sessionForTopicNotFound": self = .sessionForTopicNotFound
        default: return nil
        }
    }
}

struct WalletConnectV2ErrorMappingUtils {
    func mapWCv2Error(_ error: Error) -> WalletConnectV2Error {
        let string = "\(error)"
        guard let mappedError = WalletConnectV2Error(from: string) else {
            return .unknown(string)
        }

        return mappedError
    }
}
