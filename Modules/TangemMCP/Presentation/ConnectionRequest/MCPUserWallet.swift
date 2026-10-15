//
//  MCPUserWallet.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import struct TangemFoundation.UserWalletId
public import enum TangemUI.ThumbnailWalletViewType

public struct MCPUserWallet: Equatable, Identifiable {
    public let id: UserWalletId
    public let thumbnail: ThumbnailWalletViewType
    public let name: String
    public let numberOfCards: UInt
    public let balance: String
    public let isLocked: Bool

    public init(
        id: UserWalletId,
        thumbnail: ThumbnailWalletViewType,
        name: String,
        numberOfCards: UInt,
        balance: String,
        isLocked: Bool
    ) {
        self.id = id
        self.thumbnail = thumbnail
        self.name = name
        self.numberOfCards = numberOfCards
        self.balance = balance
        self.isLocked = isLocked
    }
}
