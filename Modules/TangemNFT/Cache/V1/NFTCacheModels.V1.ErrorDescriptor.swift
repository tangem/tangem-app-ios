//
//  NFTCacheModels.V1.ErrorDescriptor.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

extension NFTCachedModels.V1 {
    struct ErrorDescriptor: Codable {
        let code: Int
        let description: String

        init(from errorDescriptor: NFTErrorDescriptor) {
            code = errorDescriptor.code
            description = errorDescriptor.description
        }
    }
}

extension NFTCachedModels.V1.ErrorDescriptor {
    func toNFTErrorDescriptor() -> NFTErrorDescriptor {
        NFTErrorDescriptor(code: code, description: description)
    }
}
