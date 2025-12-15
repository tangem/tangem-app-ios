//
//  WalletModelResolving.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol WalletModelResolving {
    associatedtype Result

    func resolve(walletModel: CommonWalletModel) -> Result
    func resolve(walletModel: NFTSendWalletModelProxy) -> Result
    func resolve(walletModel: VisaWalletModel) -> Result
}
