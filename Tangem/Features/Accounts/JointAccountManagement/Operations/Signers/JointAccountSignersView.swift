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
    let viewModel: JointAccountSignersViewModel

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
            $0.sheetBackgroundColor = DesignSystem.Color.bgSecondary
            $0.backgroundInteractionBehavior = .tapToDismiss
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

// MARK: - Previews

#Preview {
    JointAccountSignersView(
        viewModel: JointAccountSignersViewModel(
            membersCount: 5,
            signers: [
                .init(
                    id: "0x1",
                    icon: .init(letter: "I", color: CompositeIconColorPalette.color(for: .azure)),
                    name: "Isaac",
                    answer: .created(at: "15:34, Today")
                ),
                .init(
                    id: "0x2",
                    icon: .init(letter: "K", color: CompositeIconColorPalette.color(for: .pelati)),
                    name: "Kingston",
                    answer: .signed(at: "15:36, Today")
                ),
                .init(
                    id: "0x3",
                    icon: .init(letter: "D", color: CompositeIconColorPalette.color(for: .candyGrapeFizz)),
                    name: "Daniel",
                    answer: .declined
                ),
                .init(
                    id: "0x4",
                    icon: .init(letter: "O", color: CompositeIconColorPalette.color(for: .mexicanPink)),
                    name: "Olivia",
                    answer: .waiting
                ),
                .init(
                    id: "0x5",
                    icon: .init(letter: "Y", color: CompositeIconColorPalette.color(for: .ufoGreen)),
                    name: "Yasmin",
                    answer: .waiting
                ),
            ],
            coordinator: nil
        )
    )
    .frame(maxHeight: .infinity, alignment: .bottom)
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}
