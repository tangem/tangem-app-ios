//
//  SelectorReceiveAssetsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemLocalization

struct SelectorReceiveAssetsView: View {
    @ObservedObject var viewModel: SelectorReceiveAssetsViewModel

    var body: some View {
        GroupedScrollView(contentType: .lazy(alignment: .center, spacing: Layout.Container.spacingContent)) {
            ForEach(viewModel.sections, id: \.id) { section in
                sectionView(viewModels: section.items)
            }

            notifications
        }
        .padding(.top, Layout.Container.paddingTop)
        .padding(.bottom, Layout.Container.paddingBottom)
        .onAppear(perform: viewModel.onViewAppear)
    }

    private func sectionView(viewModels: [SelectorReceiveAssetsContentItemViewModel]) -> some View {
        ForEach(viewModels, id: \.id) {
            SelectorReceiveAssetsContentItemView(viewModel: $0)
        }
    }

    @ViewBuilder
    private var notifications: some View {
        if let notificationInputs = viewModel.notificationInputs.nilIfEmpty {
            VStack(spacing: Layout.Notification.verticalSpacing) {
                if FeatureProvider.isAvailable(.redesign) {
                    RedesignedReceiveNotificationsView(inputs: notificationInputs)
                        // Tops the 12pt scroll gap up to the 14pt dots→banner spacing from Figma.
                        .padding(.top, 2)
                } else {
                    // [REDACTED_INFO]: drop the legacy NotificationView once redesign ships.
                    ForEach(notificationInputs) { input in
                        NotificationView(input: input)
                    }
                }
            }
        }
    }
}

extension SelectorReceiveAssetsView {
    private enum Layout {
        enum Notification {
            static let verticalSpacing: CGFloat = 14.0
        }

        enum Container {
            static let spacingContent: CGFloat = 12.0
            static let paddingBottom: CGFloat = 16.0
            static let paddingTop: CGFloat = 12.0
        }
    }
}
