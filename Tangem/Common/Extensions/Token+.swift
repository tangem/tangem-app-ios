//
//  Token+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
#if !CLIP
import BlockchainSdk
#endif

extension Token: Identifiable {
    public var id: Int { return hashValue }
    
    var color: Color {
        let defaultValue = Color.tangemGrayLight4
        let hexPart = contractAddress.drop0xPrefix
        if hexPart.hexToInteger != nil {
            let hex = String(hexPart.prefix(6)) + "FF"
            return Color(hex: hex) ?? defaultValue
            
            // I've used this code insted of ready TangemSdk hexString property because of two identical Token types in TangemSdk and BlockchainSdk.
            // This code will be simplified after refactoring token storage on card and on phone
        } else if let hexString = contractAddress.data(using: .utf8)?.map({ return String(format: "%02X", $0) }).joined(),
                  hexString.count >= 8 {
            return Color(hex: hexString.drop0xPrefix.suffix(6) + "FF") ?? defaultValue
        }
        return defaultValue
    }
}
