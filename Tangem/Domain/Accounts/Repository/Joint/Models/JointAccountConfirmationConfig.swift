//
//  JointAccountConfirmationConfig.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct JointAccountConfirmationConfig {
    let signedConfig: JointAccountSignedConfig
    let safeAddress: String
    let derivationIndex: Int
}
