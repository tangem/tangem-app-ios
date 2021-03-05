//
//  Token+.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import SwiftUI

extension Token: Identifiable {
    public var id: Int { return hashValue }
    
    var color: Color {
        let hex = String(contractAddress.dropFirst(2).prefix(6)) + "FF"
        return Color(hex: hex) ?? Color.tangemTapGrayLight4
    }
}
