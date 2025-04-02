//
//  BlockchainScan.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension BlockaidDTO {
    protocol ScanBlockchainRequest: Encodable {        
        var accountAddress: String? { get }
        var options: [Option] { get }
        var metadata: Metadata { get }        
    }
    
    enum Option: String, Encodable {
        case simulation
        case validation
    }
    
    struct Metadata: Encodable {
        let domain: String
    }
    
    struct ScanBlockchainResponse: Decodable {
        let validation: Validation?
        let simulation: Simulation?
        let block: String
        let chain: Chain
        let accountAddress: String
    }
}

extension BlockaidDTO.ScanBlockchainRequest {
    var options: [BlockaidDTO.Option] {
        [.simulation, .validation]
    }
}
