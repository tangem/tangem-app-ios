//
//  APIProviderType.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

enum APIProvider: String {
    case blink
    case nownodes
    case quicknode
    case getblock
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
    case dwellirBittensor
    case onfinalityBittensor
    case tangemAlephium
    case koinospro
    case tatum
    case mock

    var blockchainProvider: NetworkProviderType {
        switch self {
        case .blink: return .blink
        case .nownodes: return .nowNodes
        case .quicknode: return .quickNode
        case .getblock: return .getBlock
        case .blockchair: return .blockchair
        case .blockcypher: return .blockcypher
        case .ton: return .ton
        case .tron: return .tron
        case .arkhiaHedera: return .arkhiaHedera
        case .infura: return .infura
        case .adalite: return .adalite
        case .tangemRosetta: return .tangemRosetta
        case .fireAcademy: return .fireAcademy
        case .tangemChia: return .tangemChia
        case .tangemChia3: return .tangemChia3
        case .solana: return .solana
        case .kaspa: return .kaspa
        case .dwellirBittensor: return .dwellir
        case .onfinalityBittensor: return .onfinality
        case .tangemAlephium: return .tangemAlephium
        case .koinospro: return .koinosPro
        case .tatum: return .tatum
        case .mock: return .mock
        }
    }
}
