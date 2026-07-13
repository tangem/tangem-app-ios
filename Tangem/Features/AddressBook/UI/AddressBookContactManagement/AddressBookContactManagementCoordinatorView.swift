//
//  AddressBookContactManagementCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct AddressBookContactManagementCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: AddressBookContactManagementCoordinator

    var body: some View {
        NavigationStack {
            if let rootViewModel = coordinator.rootViewModel {
                AddressBookContactManagementView(viewModel: rootViewModel)
                    .navigationLinks(links)
            }
        }
        .sheet(item: $coordinator.qrScanCoordinator) {
            MainQRScanCoordinatorView(coordinator: $0)
                .ignoresSafeArea()
        }
        .sheet(item: $coordinator.chooseNetworkViewModel) { viewModel in
            ChooseNetworkView(viewModel: viewModel)
        }
        .floatingSheetContent(for: AddressActionsViewModel.self) { viewModel in
            AddressActionsView(viewModel: viewModel)
        }
        .floatingSheetContent(for: AccountSelectorViewModel.self) { [weak coordinator] viewModel in
            FloatingSheetContentWithHeader(
                headerConfig: .init(
                    title: viewModel.state.navigationBarTitle,
                    backAction: nil,
                    closeAction: { coordinator?.dismissWalletPicker() }
                ),
                content: {
                    VStack(spacing: 12) {
                        AccountSelectorView(viewModel: viewModel, style: .addTokenRedesigned)

                        TangemButtonV2(
                            label: AttributedString(Localization.commonCancel),
                            accessibilityLabel: Localization.commonCancel,
                            action: { coordinator?.dismissWalletPicker() }
                        )
                        .styleType(.secondary)
                        .size(.x12)
                        .horizontalLayout(.infinity)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
            )
            .floatingSheetConfiguration { config in
                config.sheetBackgroundColor = DesignSystem.Color.bgPrimary
            }
        }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.addAddressViewModel) {
                AddressBookAddAddressView(viewModel: $0)
            }
    }
}
