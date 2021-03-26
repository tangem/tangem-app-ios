//
//  Token+.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdkClips

extension Token: Identifiable {
    public var id: Int { return hashValue }
    
    var color: Color {
        let hex = String(contractAddress.dropFirst(2).prefix(6)) + "FF"
        return Color(hex: hex) ?? Color.tangemTapGrayLight4
    }
}
