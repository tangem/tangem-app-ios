//
//  JointAccountPayloadBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// - Note: Both arguments come from the derivation rather than from the builder, so that what the payload declares
/// cannot disagree with the path the key was actually derived at.
protocol JointAccountPayloadBuilder {
    associatedtype Payload: Encodable

    func makePayload(address: String, derivationIndex: Int) -> Payload
}
