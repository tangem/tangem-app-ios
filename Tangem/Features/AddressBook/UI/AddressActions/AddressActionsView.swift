//
//  AddressActionsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization
import BlockchainSdk

struct AddressActionsView: View {
    let viewModel: AddressActionsViewModel

    var body: some View {
        VStack(spacing: 0) {
            FloatingSheetNavigationBarView(
                backgroundColor: .clear,
                closeButtonAction: viewModel.close
            )

            VStack(spacing: 32) {
                details
                actionButtons
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .floatingSheetConfiguration { configuration in
            configuration.backgroundInteractionBehavior = .tapToDismiss
            configuration.sheetBackgroundColor = DesignSystem.Color.bgSecondary
        }
    }

    private var details: some View {
        VStack(spacing: 32) {
            AddressBlockiesIconView(viewData: viewModel.addressIcon, size: 72)

            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text(viewModel.address)
                        .style(DesignSystem.Font.headingSmallToken, color: DesignSystem.Color.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(viewModel.networksSubtitle)
                        .style(DesignSystem.Font.subheadingMediumToken, color: DesignSystem.Color.textSecondary)
                }

                copyButton
            }
        }
    }

    private var copyButton: some View {
        TangemButtonV2(
            label: AttributedString(Localization.addressBookCopyAddress),
            iconEnd: DesignSystem.Icons.Copy.regular20,
            accessibilityLabel: Localization.addressBookCopyAddress,
            action: viewModel.copy
        )
        .styleType(.secondary)
        .size(.x9)
        .horizontalLayout(.intrinsic)
    }

    private var actionButtons: some View {
        VStack(spacing: 8) {
            TangemButtonV2(
                label: removeLabel,
                accessibilityLabel: Localization.addressBookRemoveAddress,
                action: viewModel.remove
            )
            .styleType(.secondary)
            .size(.x12)
            .horizontalLayout(.infinity)

            TangemButtonV2(
                label: AttributedString(Localization.addressBookEditAddress),
                accessibilityLabel: Localization.addressBookEditAddress,
                action: viewModel.edit
            )
            .styleType(.secondary)
            .size(.x12)
            .horizontalLayout(.infinity)
        }
    }

    private var removeLabel: AttributedString {
        var label = AttributedString(Localization.addressBookRemoveAddress)
        label.foregroundColor = DesignSystem.Color.textAccentRed
        return label
    }
}

// MARK: - Previews

#Preview {
    final class AddressActionsPreviewStub: AddressActionsOutput, AddressActionsRoutable {
        func addressActionsDidRequestCopy(_ group: AddressBookContactAddressGroup) {}
        func addressActionsDidRequestEdit(_ group: AddressBookContactAddressGroup) {}
        func addressActionsDidRequestRemove(_ group: AddressBookContactAddressGroup) {}
        func dismissAddressActions() {}
    }

    return AddressActionsView(
        viewModel: AddressActionsViewModel(
            group: .init(
                address: "0xBef7B36845000000000000ac4e6752A9cE000000",
                memo: nil,
                networks: [
                    .init(id: .init(), blockchain: .ethereum(testnet: false)),
                    .init(id: .init(), blockchain: .polygon(testnet: false)),
                ]
            ),
            output: AddressActionsPreviewStub(),
            routable: AddressActionsPreviewStub()
        )
    )
    .frame(maxHeight: .infinity, alignment: .bottom)
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}
