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

        init(dAppData: WalletConnectDAppData, verificationStatus: WalletConnectDAppVerificationStatus) {
            self.init(
                iconURL: dAppData.icon,
                name: dAppData.name,
                domain: dAppData.domain,
                domainIsVerified: verificationStatus.isVerified
            )
        }

        init(iconURL: URL?, name: String, domain: URL?, domainIsVerified: Bool? = nil) {
            self.iconURL = iconURL
            self.name = name
            self.domain = domain?.host ?? ""
            verifiedDomainIconAsset = domainIsVerified == true
                ? Assets.Glyphs.verified
                : nil
        }
    }
}
