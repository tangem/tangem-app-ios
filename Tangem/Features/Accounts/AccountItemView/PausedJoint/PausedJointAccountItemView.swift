//
//  PausedJointAccountItemView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccounts
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct PausedJointAccountItemView: View {
    @ObservedObject var viewModel: PausedJointAccountItemViewModel

    private var cornerRadius: CGFloat = 14
    private var backgroundColor: Color = DesignSystem.Color.bgSecondary

    init(viewModel: PausedJointAccountItemViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        SwiftUI.Button(action: viewModel.onSelect) {
            Row(title: viewModel.name, subtitle: Localization.jointAccountMainPausedForSafety)
                .start {
                    AccountIconView(
                        data: viewModel.iconData.applyingLetterConfig(AccountItemConstants.letterConfig),
                        settings: AccountItemConstants.collapsedIconSettings
                    )
                }
                .end {
                    Badge(label: Localization.jointAccountMainUnavailable, accessibilityLabel: nil)
                        .appearance(.warning)
                }
                .includeInnerPadding(false)
                .padding(Constants.contentPadding)
                .background(backgroundColor)
                .cornerRadiusContinuous(cornerRadius)
                .contentShape(.rect)
        }
        .buttonStyle(.scaled(dimmingAmount: 0.7))
    }
}

// MARK: - Setupable

extension PausedJointAccountItemView: Setupable {
    func cornerRadius(_ cornerRadius: CGFloat) -> Self {
        map { $0.cornerRadius = cornerRadius }
    }

    func backgroundColor(_ backgroundColor: Color) -> Self {
        map { $0.backgroundColor = backgroundColor }
    }
}

// MARK: - Constants

private extension PausedJointAccountItemView {
    enum Constants {
        static let contentPadding: CGFloat = 12
    }
}
