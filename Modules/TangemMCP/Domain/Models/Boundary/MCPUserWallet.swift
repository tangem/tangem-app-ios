//
//  MCPUserWallet.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import struct TangemFoundation.UserWalletId
public import enum TangemUI.ThumbnailWalletViewType

// [REDACTED_TODO_COMMENT]

public struct MCPUserWallet: Equatable, Identifiable, Sendable {
    public let id: UserWalletId
    public let thumbnail: ThumbnailWalletViewType?
    public let name: String
    public let numberOfCards: Int
    public let isLocked: Bool

    public init(
        id: UserWalletId,
        thumbnail: ThumbnailWalletViewType?,
        name: String,
        numberOfCards: Int,
        isLocked: Bool
    ) {
        self.id = id
        self.thumbnail = thumbnail
        self.name = name
        self.numberOfCards = numberOfCards
        self.isLocked = isLocked
    }
}
