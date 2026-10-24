//
//  MainNotificationsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct MainNotificationsView: View {
    @ObservedObject var viewModel: MainNotificationsViewModel

    var body: some View {
        if viewModel.sections.isEmpty {
            EmptyView()
        } else {
            VStack(spacing: 12) {
                ForEach(viewModel.sections) { section in
                    switch section {
                    case .marketing(let promotionNotificationsViewModel):
                        PromotionNotificationsView(viewModel: promotionNotificationsViewModel)
                    case .systemBanners(let items):
                        NotificationBannerContainer(items: items, stackingType: .carousel)
                    }
                }
            }
        }
    }
}
