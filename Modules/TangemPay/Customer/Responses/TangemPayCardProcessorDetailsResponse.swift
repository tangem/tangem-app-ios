//
//  TangemPayCardProcessorDetailsResponse.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct TangemPayCardProcessorDetailsResponse: Decodable {
    public let cardId: String
    public let cardSecret: String?
}
