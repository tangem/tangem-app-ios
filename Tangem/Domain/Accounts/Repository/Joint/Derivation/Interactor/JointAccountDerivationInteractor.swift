//
//  JointAccountDerivationInteractor.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol JointAccountDerivationInteractor {
    func deriveAndSign<Builder: JointAccountPayloadBuilder>(
        derivationIndex: Int,
        payloadBuilder: Builder
    ) async throws -> JointAccountDerivationInteractorResult<Builder.Payload>
}

struct JointAccountDerivationInteractorResult<Payload: Encodable> {
    let payload: Payload
    let derivedKey: JointAccountDerivedKey
    let signature: Data
}

protocol JointAccountDerivationInteractorProvider: AnyObject {
    var jointAccountDerivationInteractor: JointAccountDerivationInteractor { get }
}

/// For a wallet that cannot derive at all: a locked one, a preview, or a model that has gone away.
struct UnavailableJointAccountDerivationInteractor: JointAccountDerivationInteractor {
    func deriveAndSign<Builder: JointAccountPayloadBuilder>(
        derivationIndex: Int,
        payloadBuilder: Builder
    ) async throws -> JointAccountDerivationInteractorResult<Builder.Payload> {
        throw "This wallet cannot derive a joint account's key"
    }
}
