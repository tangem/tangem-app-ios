//
//  JointAccountSignersView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI

/// Who has answered an operation of a joint account, and when.
///
/// Every member of the account is listed, including the ones that have not answered: the endpoint reports the
/// answers alone, so the rest are worked out from the account's composition.
struct JointAccountSignersView: View {
    @ObservedObject var viewModel: JointAccountSignersViewModel

    var body: some View {
        VStack(spacing: .zero) {
            FloatingSheetNavigationBarView(
                title: Localization.jointOperationSignersTitle,
                subtitle: Localization.jointAccountMembersCount(viewModel.membersCount),
                backgroundColor: DesignSystem.Color.bgSecondary,
                backButtonAction: viewModel.onBackTap,
                closeButtonAction: viewModel.onCloseTap
            )

            // Flush to the sheet's edges: the inset under the text comes from each row's own padding
            signers
                .padding(.bottom, Constants.contentBottomPadding)
        }
        .floatingSheetConfiguration {
            $0.sheetBackground = .color(DesignSystem.Color.bgSecondary)
            $0.backgroundInteractionBehavior = .tapToDismiss
            $0.sheetFrameUpdateAnimation = .contentFrameUpdate
        }
    }

    private var signers: some View {
        ScrollView(.vertical) {
            VStack(spacing: .zero) {
                ForEach(viewModel.signers) { signer in
                    JointAccountSignerRow(viewData: signer)
                }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

// MARK: - Constants

private extension JointAccountSignersView {
    enum Constants {
        static let contentBottomPadding: CGFloat = 8
    }
}

// MARK: - Content transition

private extension Animation {
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
}
