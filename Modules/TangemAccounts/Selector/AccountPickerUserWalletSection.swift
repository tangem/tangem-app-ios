//
//  AccountPickerUserWalletSection.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemUI

public struct AccountPickerUserWalletSection: Identifiable {
    public let id: String
    public let header: Header?
    public let accounts: [AccountPickerAccountItem]

    public init(id: String, header: Header?, accounts: [AccountPickerAccountItem]) {
        self.id = id
        self.header = header
        self.accounts = accounts
    }

    public struct Header {
        public let name: String
        public let thumbnail: ThumbnailWalletViewType?

        public init(name: String, thumbnail: ThumbnailWalletViewType?) {
            self.name = name
            self.thumbnail = thumbnail
        }
    }
}
