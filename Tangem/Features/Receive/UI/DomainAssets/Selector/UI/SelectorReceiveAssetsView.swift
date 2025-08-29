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
        GroupedScrollView(spacing: Layout.Container.spacingContent) {
            if let notificationInputs = viewModel.notificationInputs.nilIfEmpty {
                VStack(spacing: Layout.Notification.verticalSpacing) {
                    ForEach(notificationInputs) { input in
                        NotificationView(input: input)
                    }
                }
                .padding(.bottom, Layout.Notification.bottomPadding)
            }

            ForEach(viewModel.sections, id: \.id) { section in
                sectionView(header: section.header, viewModels: section.items)
            }
        }
        .padding(.bottom, Layout.Container.paddingBottom)
        .onAppear(perform: viewModel.onViewAppear)
    }

    private func sectionView(
        header: SelectorReceiveAssetsSection.Header?,
        viewModels: [SelectorReceiveAssetsContentItemViewModel]
    ) -> some View {
        GroupedSection(viewModels) {
            SelectorReceiveAssetsContentItemView(viewModel: $0)
        } header: {
            if let header, case .title(let text) = header {
                DefaultHeaderView(text)
                    .padding(.init(top: 10, leading: 0, bottom: 6, trailing: 0))
            }
        }
        .backgroundColor(Colors.Background.action)
    }
}

extension SelectorReceiveAssetsView {
    private enum Layout {
        enum NavigationBar {
            static let verticalPadding: CGFloat = 4
            static let horizontalPadding: CGFloat = 16
        }

        enum Notification {
            static let verticalSpacing: CGFloat = 14.0
            static let bottomPadding: CGFloat = 4
        }

        enum Container {
            static let spacingContent: CGFloat = 8.0
            static let paddingBottom: CGFloat = 16.0
        }
    }
}
