//
//  SignData.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//
import TangemSdk

public struct SignData {
    public let derivationPath: DerivationPath
    public let hash: Data
    public let publicKey: Data
}
