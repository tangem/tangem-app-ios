//
//  PublicKeyProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public protocol PublicKeyProvider {
    var publicKey: Data { get }
}
