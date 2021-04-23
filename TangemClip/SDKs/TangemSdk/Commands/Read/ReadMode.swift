//
//  ReadMode.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

/// Available modes for reading card information
/// - Note: This modes available for cards with COS v.4.0 and higher
public enum ReadMode: Byte, InteractionMode {
    /// Return only information about card without wallet data
    case readCard = 0x01
    /// use this mode when you want to read card information and single wallet from card. Specify wallet you want to read with `WalletIndex`
    case readWallet = 0x02
    /// Returns card and list of available wallets
    case readWalletList = 0x03
}
