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
                switch section.id {
                case .default:
                    defaultSectionView(viewModels: section.items)
                case .domain:
                    domainSectionView(viewModels: section.items)
                }
            }

            if let notificationInputs = viewModel.notificationInputs.nilIfEmpty {
                VStack(spacing: Layout.Notification.verticalSpacing) {
                    ForEach(notificationInputs) { input in
                        NotificationView(input: input)
                    }
                }
            }
        }
        .padding(.top, Layout.Container.paddingTop)
        .padding(.bottom, Layout.Container.paddingBottom)
    }

    private func defaultSectionView(viewModels: [SelectorReceiveAssetsContentItemViewModel]) -> some View {
        ForEach(viewModels, id: \.id) {
            SelectorReceiveAssetsContentItemView(viewModel: $0)
        }
    }

    private func domainSectionView(viewModels: [SelectorReceiveAssetsContentItemViewModel]) -> some View {
        ForEach(viewModels, id: \.id) {
            SelectorReceiveAssetsContentItemView(viewModel: $0)
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
