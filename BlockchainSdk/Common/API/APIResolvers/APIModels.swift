//
//  APIModels.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.

import Foundation
import TangemNetworkUtils
import TangemFoundation

public typealias APIList = [String: [NetworkProviderType]]

public enum NetworkProviderType: Equatable, Hashable, Codable {
    case `public`(link: String)
    case nowNodes
    case blink
    case quickNode
    case getBlock
    case blockchair
    case blockcypher
    case ton
    case tron
    case arkhiaHedera
    case infura
    case adalite
    case tangemRosetta
    case fireAcademy
    case tangemChia
    case tangemChia3
    case solana
    case kaspa
    case dwellir
    case onfinality
    case koinosPro
    case tangemAlephium
    case tatum
    case mock
}

extension NetworkProviderType {
    var isPrivateMempool: Bool {
        switch self {
        case .blink: true
        default: false
        }
    }
}

struct NodeInfo: HostProvider {
    let url: URL
    let headers: APIHeaderKeyInfo?

    var link: String { url.absoluteString }

    var host: String { url.hostOrUnknown }

    init(url: URL, keyInfo: APIHeaderKeyInfo? = nil) {
        self.url = url
        headers = keyInfo
    }
}
