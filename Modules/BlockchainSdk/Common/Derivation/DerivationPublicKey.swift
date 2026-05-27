//
//  DerivationPublicKey.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct DerivationPublicKey: Hashable {
    public let publicKey: Data
    public let derivationPath: DerivationPath?

    public init(publicKey: Data, derivationPath: DerivationPath?) {
        self.publicKey = publicKey
        self.derivationPath = derivationPath
    }
}
