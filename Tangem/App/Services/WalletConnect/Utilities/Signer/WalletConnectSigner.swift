//
//  WalletConnectSigner.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

protocol WalletConnectSigner {
    func sign(data: Data, using walletModel: WalletModel) async throws -> String
}
