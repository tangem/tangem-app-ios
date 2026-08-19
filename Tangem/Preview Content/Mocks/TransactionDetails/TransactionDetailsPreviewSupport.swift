//
//  TransactionDetailsPreviewSupport.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation

/// Preview-only `TransactionHistoryService` that immediately reports `.loaded` and serves a fixed set of records,
/// so `CommonWalletModel.transactionHistoryPublisher` emits `.loaded(items:)` and the details screen exercises
/// the real subscription / mapping path.
final class PreviewTransactionHistoryService {
    private let records: [TransactionRecord]

    init(records: [TransactionRecord]) {
        self.records = records
    }
}

// MARK: - TransactionHistoryService

extension PreviewTransactionHistoryService: TransactionHistoryService {
    var state: TransactionHistoryServiceState { .loaded }

    var statePublisher: AnyPublisher<TransactionHistoryServiceState, Never> {
        .just(output: .loaded)
    }

    var items: [TransactionRecord] {
        get async { records }
    }

    func update() -> AnyPublisher<Void, Never> {
        .just(output: ())
    }
}

// MARK: - TransactionHistoryFetcher

extension PreviewTransactionHistoryService {
    var canFetchHistory: Bool { false }

    func clearHistory() async {}
}

// MARK: - No-op routable

final class NoopTransactionDetailsRoutable: TransactionDetailsRoutable {
    func openTransactionDetailsURL(_ url: URL) {}
    func shareFromTransactionDetails(_ text: String) {}
    #if INTERNAL || DEBUG
    func openTransactionDetailsDebug(_ info: TransactionDetailsDebugInfo) {}
    #endif
    func closeTransactionDetails() {}
}

// MARK: - Wallet model factory

extension CommonWalletModel {
    /// Builds a wallet model backed by a `PreviewTransactionHistoryService` seeded with `history`, mirroring
    /// `CommonWalletModel.mockETH` but with a live history service instead of `nil`.
    static func previewWalletModel(history: [TransactionRecord]) -> CommonWalletModel {
        let walletManager = EthereumWalletManagerMock()
        let blockchain = walletManager.wallet.blockchain
        let derivationPath = walletManager.wallet.publicKey.derivationPath
        let blockchainNetwork = BlockchainNetwork(blockchain, derivationPath: derivationPath)
        let tokenItem = TokenItem.blockchain(blockchainNetwork)
        let mobileWalletInfo = MobileWalletInfo(
            hasMnemonicBackup: false,
            hasICloudBackup: false,
            accessCodeStatus: .none,
            keys: []
        )

        let config = UserWalletConfigFactory().makeConfig(mobileWalletInfo: mobileWalletInfo)
        let hwLimitationsUtil = HardwareLimitationsUtil(config: config)
        let sendAvailabilityProvider = TransactionSendAvailabilityProvider(hardwareLimitationsUtil: hwLimitationsUtil)

        return CommonWalletModel(
            userWalletId: .init(with: Data()),
            tokenItem: tokenItem,
            walletManager: walletManager,
            stakingManager: StakingManagerMock(),
            featureManager: WalletModelFeaturesManagerMock(),
            transactionHistoryUpdater: TransactionHistoryUpdater(
                scheduledUpdatesStorage: TransactionHistoryScheduledUpdatesStorage()
            ),
            transactionHistoryService: PreviewTransactionHistoryService(records: history),
            receiveAddressService: DummyReceiveAddressService(addressInfos: []),
            sendAvailabilityProvider: sendAvailabilityProvider,
            tokenBalancesRepository: TokenBalancesRepositoryMock(),
            isCustom: false
        )
    }
}
