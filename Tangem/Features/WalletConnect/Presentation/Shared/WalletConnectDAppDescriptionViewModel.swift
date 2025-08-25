//
//  WalletConnectDAppDescriptionViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.URL
import TangemAssets

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
        let verifiedDomainIconAsset: ImageType?

        private init(iconURL: URL?, name: String, domain: String, verifiedDomainIconAsset: ImageType?) {
            self.iconURL = iconURL
            self.name = name
            self.domain = domain
            self.verifiedDomainIconAsset = verifiedDomainIconAsset
        }

        init(dAppData: WalletConnectDAppData, verificationStatus: WalletConnectDAppVerificationStatus) {
            self.init(
                iconURL: dAppData.icon,
                name: dAppData.name,
                domain: dAppData.domain.host ?? "",
                verifiedDomainIconAsset: verificationStatus.isVerified
                    ? Assets.Glyphs.verified
                    : nil
            )
        }
    }
}
