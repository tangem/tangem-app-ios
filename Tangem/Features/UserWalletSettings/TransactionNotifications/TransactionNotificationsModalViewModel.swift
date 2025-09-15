//
//  TransactionNotificationsModalViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import struct TangemUIUtils.AlertBinder
import BlockchainSdk
import TangemLocalization
import protocol TangemUI.FloatingSheetContentViewModel

final class TransactionNotificationsModalViewModel: ObservableObject {
    // MARK: - Services

    @Injected(\.tangemApiService) var tangemApiService: TangemApiService

    // MARK: - Published Properties

    @Published var tokenItemViewModels: [TransactionNotificationsItemViewModel] = []
    @Published var alert: AlertBinder?

    // MARK: - Private Implementation

    private var loadableTask: Task<Void, Error>?

    private weak var coordinator: TransactionNotificationsModalRoutable?

    // MARK: - Init

    init(coordinator: TransactionNotificationsModalRoutable?) {
        self.coordinator = coordinator
        setupUI()
        loadAndDisplayNetworkItems()
    }

    deinit {
        loadableTask?.cancel()
    }

    // MARK: - Implementation

    func onGotItTapAction() {
        coordinator?.dismissTransactionNotifications()
    }

    // MARK: - Private Implementation

    private func setupUI() {
        let imageProvider = NetworkImageProvider()
        tokenItemViewModels = SupportedBlockchains.all.map { blockchain in
            TransactionNotificationsItemViewModel(
                networkName: blockchain.displayName,
                networkSymbol: blockchain.currencySymbol,
                iconImageAsset: imageProvider.provide(by: blockchain, filled: true),
                isLoading: true
            )
        }
    }

    private func loadAndDisplayNetworkItems() {
        loadableTask = runTask { [weak self] in
            guard let self else {
                return
            }

            do {
                let response = try await tangemApiService.pushNotificationsEligibleNetworks()

                await runOnMain {
                    self.mapAndDisplayEligibleNetworks(response: response)
                }
            } catch {
                AppLogger.error(error: error)

                // Fallback as a last resort
                displayAlert(error: error)
            }
        }
    }
}

// MARK: - Private Implementation

private extension TransactionNotificationsModalViewModel {
    private func mapAndDisplayEligibleNetworks(response: [NotificationDTO.NetworkItem]) {
        let imageProvider = NetworkImageProvider()

        let viewModels: [TransactionNotificationsItemViewModel] = response.compactMap {
            // We should find and use a exactly same blockchain that in the supportedBlockchains set
            guard let blockchain = SupportedBlockchains.all[$0.networkId] else {
                return nil
            }

            return TransactionNotificationsItemViewModel(
                networkName: blockchain.displayName,
                networkSymbol: blockchain.currencySymbol,
                iconImageAsset: imageProvider.provide(by: blockchain, filled: true),
                isLoading: false
            )
        }

        tokenItemViewModels = viewModels
    }
}

// MARK: - Alerts

private extension TransactionNotificationsModalViewModel {
    func displayAlert(error: Error) {
        alert = AlertBinder(title: Localization.commonError, message: error.localizedDescription)
    }
}

// MARK: - FloatingSheetContentViewModel

extension TransactionNotificationsModalViewModel: FloatingSheetContentViewModel {}
