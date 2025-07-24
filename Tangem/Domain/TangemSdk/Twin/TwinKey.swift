//
//  TwinKey.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//
import Foundation

struct TwinKey {
    let key1: Data
    let key2: Data

    func getPairKey(for walletPublicKey: Data) -> Data? {
        if walletPublicKey == key1 {
            return key2
        }

        if walletPublicKey == key2 {
            return key1
        }

        return nil
    }
}
