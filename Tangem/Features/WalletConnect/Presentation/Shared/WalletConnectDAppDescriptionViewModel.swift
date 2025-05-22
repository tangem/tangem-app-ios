//
//  WalletConnectDAppDescriptionViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.URL
import enum TangemAssets.Assets

enum WalletConnectDAppDescriptionViewModel: Equatable {
    case loading
    case content(ContentState)

    var isLoading: Bool {
        switch self {
        case .loading: true
        case .content: false
        }
    }
}

extension WalletConnectDAppDescriptionViewModel {
    struct ContentState: Equatable {
        let iconURL: URL?
        let fallbackIconAsset = Assets.Glyphs.explore
        let name: String
        let domain: String

        init(dAppData: WalletConnectDAppData) {
            self.init(iconURL: dAppData.icon, name: dAppData.name, domain: dAppData.domain)
        }

        init(iconURL: URL?, name: String, domain: URL?) {
            self.iconURL = iconURL
            self.name = name
            self.domain = domain?.host ?? ""
        }
    }
}
