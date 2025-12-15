//
//  TransactionNotificationsRowToggleView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct TransactionNotificationsRowToggleView: View {
    @ObservedObject private(set) var viewModel: TransactionNotificationsRowToggleViewModel

    var body: some View {
        VStack(spacing: Layout.spacingGroupedSections) {
            GroupedSection(viewModel.warningPermissionViewModel) {
                DefaultWarningRow(viewModel: $0)
            }

            GroupedSection(viewModel.pushNotifyViewModel) {
                DefaultToggleRowView(viewModel: $0)
            } footer: {
                Button(action: viewModel.onTapMoreInfoTransactionPushNotifications) {
                    Group {
                        Text("\(Localization.walletSettingsPushNotificationsDescription) ")
                            + readMoreText
                    }
                    .style(Fonts.Regular.footnote, color: Colors.Text.tertiary)
                    // We've calculation height problem here
                    // SUI BottomSheet can't do it normally without this `fixedSize`
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                }
            }
        }
    }

    // MARK: - Private UI

    private var readMoreText: Text {
        let readMoreText = Localization.pushNotificationsMoreInfo.replacingOccurrences(of: " ", with: AppConstants.unbreakableSpace)
        return Text(readMoreText).foregroundColor(Colors.Text.accent)
    }
}

// MARK: - Layout

private extension TransactionNotificationsRowToggleView {
    enum Layout {
        static let spacingGroupedSections: CGFloat = 14
    }
}
