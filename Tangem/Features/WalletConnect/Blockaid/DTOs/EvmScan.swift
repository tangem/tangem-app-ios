//
//  EvmScan.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

extension BlockaidDTO {
    enum EvmScan {
        struct Request: ScanBlockchainRequest {
            let accountAddress: String?
            let metadata: BlockaidDTO.Metadata
            
            let chain: BlockaidDTO.Chain
            let data: Data
            let block: String?
            
            struct Data: Encodable {
                let jsonrpc: String = "2.0"
                let params: [Params]
                let method: String
            }
            
            struct Params: Encodable {
                let from: String
                let to: String
                let data: String
                let value: String
            }
        }
    }
}
