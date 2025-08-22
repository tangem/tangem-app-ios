//
//  ReceiveAddressTypeProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Receive Addresses

protocol ReceiveAddressTypesProvider {
    var receiveAddressTypes: [ReceiveAddressType] { get }

    /// Legacy using. Remove when remove ReceiveBottomSheetView
    var receiveAddressInfos: [ReceiveAddressInfo] { get }
}
