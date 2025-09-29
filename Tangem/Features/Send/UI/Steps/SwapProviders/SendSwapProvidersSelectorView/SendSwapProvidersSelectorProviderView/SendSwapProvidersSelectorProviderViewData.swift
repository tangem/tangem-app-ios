//
//  SendSwapProvidersSelectorProviderViewData.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress
import TangemLocalization

struct SendSwapProvidersSelectorProviderViewData: Identifiable {
    let id: String
    let title: String
    let providerIcon: URL?
    let providerType: String
    let isDisabled: Bool
    let badge: Badge?
    let subtitles: [Subtitle]
}

extension SendSwapProvidersSelectorProviderViewData {
    typealias Subtitle = ProviderRowViewModel.Subtitle

    enum Badge: Hashable {
        case plain(String)
        case accent(String)

        static let permissionNeeded = Badge.plain(Localization.expressProviderPermissionNeeded)
        static let fcaWarning = Badge.plain(Localization.expressProviderFcaWarningList)
        static let bestRate = Badge.accent(Localization.expressProviderBestRate)
    }
}
