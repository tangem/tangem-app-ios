//
//  MobileWalletSecureEnclaveService.swift
//  TangemMobileWalletSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

protocol MobileWalletSecureEnclaveService {
    func encryptData(_ data: Data, keyTag: String) throws -> Data
    func decryptData(_ data: Data, keyTag: String) throws -> Data
}

extension SecureEnclaveService: MobileWalletSecureEnclaveService {}
