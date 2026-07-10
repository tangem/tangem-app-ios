//
//  TransactionDetailsViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation
import TangemUI

final class TransactionDetailsViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Published private(set) var header: TransactionDetailsHeaderViewData
    @Published private(set) var content: Content

    @Published private var isSuccessBannerDismissed = false

    private var updatesSubscription: AnyCancellable?

    /// Reactive: renders `header` / `content` and keeps them live by re-mapping each record update via
    /// `rebuild`. The mapping is injected on purpose — the sheet renders very different operations
    /// (send / receive / swap / onramp / staking / yield), each built from a `TransactionRecord` using
    /// context the VM doesn't own (token icons, Express resolution, URLs). The VM keeps ownership of the
    /// orchestration: the subscription and the success-banner lifecycle.
    init(
        header: TransactionDetailsHeaderViewData,
        content: Content,
        recordUpdates: AnyPublisher<TransactionRecord, Never>,
        rebuild: @escaping (TransactionRecord) -> (header: TransactionDetailsHeaderViewData, content: Content)
    ) {
        self.header = header
        self.content = content
        // A transaction that's already finished when the sheet opens shouldn't flash the success banner —
        // suppress it up-front. The brief show-then-hide is reserved for a live transition into success
        // (handled by `scheduleSuccessBannerDismissIfNeeded` on record updates).
        isSuccessBannerDismissed = rawBlocks.contains(where: isSuccessBanner)

        updatesSubscription = recordUpdates
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, record in
                let result = rebuild(record)
                viewModel.header = result.header
                viewModel.content = result.content
                viewModel.scheduleSuccessBannerDismissIfNeeded()
            }
    }

    var blocks: [TransactionDetailsBlock] {
        guard isSuccessBannerDismissed else { return rawBlocks }
        return rawBlocks.filter { !isSuccessBanner($0) }
    }

    private var rawBlocks: [TransactionDetailsBlock] {
        switch content {
        case .single(let data): data.blocks
        case .swap(let viewModel): viewModel.blocks
        case .onramp(let viewModel): viewModel.blocks
        case .yield(let data): data.blocks
        }
    }

    /// When a transaction completes while the sheet is open, the success banner ("Funds received") is shown
    /// briefly, then hidden — the success is already conveyed by the amounts and the title. Every other banner
    /// (in progress / failed / attention) stays as the content dictates. Once hidden it stays hidden
    /// (`isSuccessBannerDismissed` only flips `false → true`), so repeated record re-emits can't bring it back —
    /// which also keeps an already-finished transaction (suppressed in `init`) from ever flashing it.
    private func scheduleSuccessBannerDismissIfNeeded() {
        guard !isSuccessBannerDismissed, rawBlocks.contains(where: isSuccessBanner) else { return }

        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2), clock: .continuous)
            self?.isSuccessBannerDismissed = true
        }
    }

    private func isSuccessBanner(_ block: TransactionDetailsBlock) -> Bool {
        guard case .statusBanner(let data) = block else { return false }
        return data.kind == .success
    }

    enum Content {
        case single(TransactionDetailsSingleOperationViewData)
        case swap(SwapTransactionDetailsViewData)
        case onramp(OnrampTransactionDetailsViewData)
        case yield(TransactionDetailsYieldViewData)
    }
}

enum TransactionDetailsBlock: Identifiable {
    case tokens(TransactionDetailsTokensViewData)
    case yieldTokens(TransactionDetailsYieldTokensViewData)
    case statusBanner(TransactionDetailsStatusBannerViewData)
    case principalAmount(TransactionDetailsPrincipalAmountViewData)
    case counterparty(TransactionDetailsAddressViewData)
    case info(TransactionDetailsInfoSectionViewData)
    case action(TransactionDetailsActionButtonViewData)

    var id: String {
        switch self {
        case .tokens: "tokens"
        case .yieldTokens: "yieldTokens"
        case .statusBanner: "statusBanner"
        case .principalAmount: "principalAmount"
        case .counterparty: "counterparty"
        case .info: "info"
        case .action: "action"
        }
    }
}
