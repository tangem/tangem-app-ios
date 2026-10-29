//
//  StandardCryptoAccountModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// The standard kind of crypto account, dedicated interface so the double dispatch can tell it apart from the `CryptoAccountModel`.
protocol StandardCryptoAccountModel: CryptoAccountModel {}
