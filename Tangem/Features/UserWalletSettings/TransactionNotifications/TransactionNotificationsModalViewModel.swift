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
    private let supportedBlockchains: Set<Blockchain>

    private weak var coordinator: TransactionNotificationsModalRoutable?

    // MARK: - Init

    init(coordinator: TransactionNotificationsModalRoutable?) {
        self.coordinator = coordinator

        supportedBlockchains = SupportedBlockchains(version: .v2).blockchains()

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
        tokenItemViewModels = supportedBlockchains.map {
            TransactionNotificationsItemViewModel(
                blockchainNetwork: .init($0, derivationPath: nil),
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
            }
        }
    }
}

// MARK: - Private Implementation

private extension TransactionNotificationsModalViewModel {
    private func mapAndDisplayEligibleNetworks(response: [NotificationDTO.NetworkItem]) {
        let viewModels: [TransactionNotificationsItemViewModel] = response.compactMap {
            // We should find and use a exactly same blockchain that in the supportedBlockchains set
            guard let blockchain = supportedBlockchains[$0.networkId] else {
                return nil
            }

            let blockchainNetwork = BlockchainNetwork(blockchain, derivationPath: nil)

            return TransactionNotificationsItemViewModel(blockchainNetwork: blockchainNetwork)
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
