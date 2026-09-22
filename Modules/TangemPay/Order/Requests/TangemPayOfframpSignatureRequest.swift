//
//  TangemPayOfframpSignatureRequest.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct TangemPayOfframpSignatureRequest: Encodable {
    public let signature: String

    public init(signature: String) {
        self.signature = signature
    }
}
