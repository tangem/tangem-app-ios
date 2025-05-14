//
//  MoralisPaginableResponse.swift
//  TangemNFT
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol MoralisPaginableResponse {
    typealias TargetFactory = (_ cursor: String?) -> MoralisEVMAPITarget

    var cursor: String? { get }
}
