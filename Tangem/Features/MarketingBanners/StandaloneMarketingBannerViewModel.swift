//
//  StandaloneMarketingBannerViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct StandaloneMarketingBannerViewModel: Identifiable, Hashable {
    let id: Int
    let title: String
    let iconURL: URL?
    let isDismissible: Bool

    @IgnoredEquatable
    var action: (() -> Void)?

    @IgnoredEquatable
    var dismiss: (() -> Void)?

    init(
        id: Int,
        title: String,
        iconURL: URL?,
        isDismissible: Bool,
        action: (() -> Void)? = nil,
        dismiss: (() -> Void)? = nil
    ) {
        self.id = id
        self.title = title
        self.iconURL = iconURL
        self.isDismissible = isDismissible
        self.action = action
        self.dismiss = dismiss
    }
}
