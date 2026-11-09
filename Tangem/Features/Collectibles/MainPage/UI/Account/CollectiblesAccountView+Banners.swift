//
//  CollectiblesAccountView+Banners.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension CollectiblesAccountView {
    struct Banners: View {
        let relinkBannerViewModel: CollectiblesRelinkBannerViewModel?

        var body: some View {
            relinkBannerViewModel.map(CollectiblesRelinkBanner.init)
        }
    }
}
