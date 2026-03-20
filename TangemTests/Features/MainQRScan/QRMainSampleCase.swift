//
//  QRMainSampleCase.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct QRMainSampleCase: Sendable {
    let name: String
    let qr: String
    let expectedKind: QRMainSampleKind
    let expectedBlockchainCodingKey: String?
    let expectedDestination: String
    let expectedRawAmount: String?
    let expectedAmount: String?
}
