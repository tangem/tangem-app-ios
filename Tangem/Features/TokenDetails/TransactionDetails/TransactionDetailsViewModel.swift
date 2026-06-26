//
//  TransactionDetailsViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemUI

final class TransactionDetailsViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Published private(set) var header: TransactionDetailsHeaderViewData
    @Published private(set) var content: Content
    @Published private var isSuccessBannerDismissed = false

    private var updatesSubscription: AnyCancellable?
    private var successBannerDismissTask: Task<Void, Never>?

    init(
        header: TransactionDetailsHeaderViewData,
        content: Content,
        recordUpdates: AnyPublisher<TransactionRecord, Never>? = nil,
        rebuild: ((TransactionRecord) -> (header: TransactionDetailsHeaderViewData, content: Content))? = nil
    ) {
        self.header = header
        self.content = content

        isSuccessBannerDismissed = hasSuccessBanner

        if let recordUpdates, let rebuild {
            updatesSubscription = recordUpdates
                .receive(on: DispatchQueue.main)
                .sink { [weak self] record in
                    guard let self else { return }
                    let result = rebuild(record)
                    self.header = result.header
                    self.content = result.content
                    scheduleSuccessBannerDismissIfNeeded()
                }
        }
    }

    deinit {
        successBannerDismissTask?.cancel()
    }

    var blocks: [TransactionDetailsBlock] {
        guard isSuccessBannerDismissed else { return rawBlocks }
        return rawBlocks.filter { block in
            if case .statusBanner(let data) = block, data.kind == .success {
                return false
            }
            return true
        }
    }

    private var rawBlocks: [TransactionDetailsBlock] {
        switch content {
        case .send(let viewModel): viewModel.blocks
        case .receive(let viewModel): viewModel.blocks
        case .swap(let viewModel): viewModel.blocks
        case .onramp(let viewModel): viewModel.blocks
        }
    }

    private var hasSuccessBanner: Bool {
        rawBlocks.contains { block in
            if case .statusBanner(let data) = block { return data.kind == .success }
            return false
        }
    }

    private func scheduleSuccessBannerDismissIfNeeded() {
        guard hasSuccessBanner else {
            successBannerDismissTask?.cancel()
            successBannerDismissTask = nil
            isSuccessBannerDismissed = false
            return
        }

        guard !isSuccessBannerDismissed, successBannerDismissTask == nil else { return }

        successBannerDismissTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard let self, !Task.isCancelled else { return }
            isSuccessBannerDismissed = true
            successBannerDismissTask = nil
        }
    }

    enum Content {
        case send(SendTransactionDetailsViewData)
        case receive(ReceiveTransactionDetailsViewData)
        case swap(SwapTransactionDetailsViewData)
        case onramp(OnrampTransactionDetailsViewData)
    }
}

enum TransactionDetailsBlock: Identifiable {
    case tokens(TransactionDetailsTokensViewData)
    case statusBanner(TransactionDetailsStatusBannerViewData)
    case counterparty(TransactionDetailsAddressViewData)
    case info(TransactionDetailsInfoSectionViewData)
    case action(TransactionDetailsActionButtonViewData)

    var id: String {
        switch self {
        case .tokens: "tokens"
        case .statusBanner: "statusBanner"
        case .counterparty: "counterparty"
        case .info: "info"
        case .action: "action"
        }
    }
}
