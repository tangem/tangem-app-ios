//
//  SendSwapProvidersSelectorProviderViewData.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress

struct SendSwapProvidersSelectorProviderViewData: Identifiable {
    let id: String
    let title: String
    let providerIcon: URL?
    let providerType: String
    let isTappable: Bool
    let badge: Badge?
    let subtitles: [Subtitle]
}

extension SendSwapProvidersSelectorProviderViewData {
    typealias Subtitle = ProviderRowViewModel.Subtitle

    enum Badge: String, Hashable {
        case permissionNeeded
        case fcaWarning
        case bestRate
    }
}
