//
//  TangemPayOfframpCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct TangemPayOfframpCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: TangemPayOfframpCoordinator

    var body: some View {
        ZStack {
            NavigationStack(path: $coordinator.path) {
                ZStack {
                    if let rootViewModel = coordinator.rootViewModel {
                        WithdrawHubView(viewModel: rootViewModel)
                    }
                }
                .navigationDestination(
                    for: TangemPayOfframpCoordinator.Route.self,
                    destination: destination
                )
            }

            sheets
        }
    }

    @ViewBuilder
    private func destination(_ route: TangemPayOfframpCoordinator.Route) -> some View {
        switch route {
        case .recentRecipients:
            if let store = coordinator.recentRecipientsStore {
                let viewModel = RecentRecipientsViewModel(
                    recentRecipientsStore: store,
                    output: { [weak coordinator] bankAccountId in
                        coordinator?.startWizard(recipient: .saved(bankAccountId: bankAccountId))
                    }
                )
                RecentRecipientsView(viewModel: viewModel)
            }

        case .transferInput:
            if let viewModel = coordinator.transferInputViewModel {
                TransferInputView(viewModel: viewModel)
            }

        case .transferType:
            if let orderBuilder = coordinator.orderBuilder {
                TransferTypeFactory.makeView(
                    orderBuilder: orderBuilder,
                    output: { [weak coordinator] in coordinator?.handle($0) }
                )
            }

        case .accountType:
            if let orderBuilder = coordinator.orderBuilder {
                AccountTypeFactory.makeView(
                    orderBuilder: orderBuilder,
                    output: { [weak coordinator] in coordinator?.handle($0) }
                )
            }

        case .personalDetails(let mode):
            if let orderBuilder = coordinator.orderBuilder, let store = coordinator.recentRecipientsStore {
                PersonalDetailsFactory.makeView(
                    orderBuilder: orderBuilder,
                    recentRecipientsStore: store,
                    output: { [weak coordinator] in coordinator?.handle($0, mode: mode) }
                )
            }

        case .bankDetails(let mode):
            if let orderBuilder = coordinator.orderBuilder {
                BankDetailsFactory.makeView(
                    orderBuilder: orderBuilder,
                    output: { [weak coordinator] in coordinator?.handle($0, mode: mode) }
                )
            }

        case .transferConfirmation:
            if let orderBuilder = coordinator.orderBuilder, let optionsStore = coordinator.optionsStore {
                TransferConfirmationFactory.makeView(
                    orderBuilder: orderBuilder,
                    optionsStore: optionsStore,
                    savedRecipient: coordinator.activeSavedRecipient,
                    hasNFCInteraction: coordinator.hasNFCInteraction,
                    output: { [weak coordinator] in coordinator?.handle($0) }
                )
            }
        }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .floatingSheetContent(for: TangemPayWithdrawNoteSheetViewModel.self) {
                TangemPayPopupView(viewModel: $0)
            }
            .floatingSheetContent(for: TangemPayWithdrawInProgressSheetViewModel.self) {
                TangemPayWithdrawInProgressSheetView(viewModel: $0)
            }
            .floatingSheetContent(for: TangemPayNoDepositAddressSheetViewModel.self) {
                TangemPayNoDepositAddressSheetView(viewModel: $0)
            }
            .sheet(item: $coordinator.sendCoordinator) {
                SendCoordinatorView(coordinator: $0)
            }
            .sheet(isPresented: $coordinator.isCountrySelectionPresented) {
                coordinator.makeCountrySelectionView()
            }
            .sheet(isPresented: $coordinator.isRegionSelectionPresented) {
                coordinator.makeRegionSelectionView()
            }
    }
}
