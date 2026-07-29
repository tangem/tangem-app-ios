//
//  TransactionDetailsViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemExpress
import TangemFoundation
import TangemUI

final class TransactionDetailsViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Published private(set) var header: TransactionDetailsHeaderViewData?
    @Published private(set) var content: Content?

    @Published private var isSuccessBannerDismissed = false

    private var bag = Set<AnyCancellable>()

    init(
        id: TransactionRecord.ID,
        walletModel: any WalletModel,
        userWalletInfo: UserWalletInfo,
        isAccountsMode: Bool,
        routable: TransactionDetailsRoutable
    ) {
        let context = TransactionDetailsContext(
            walletModel: walletModel,
            userWalletInfo: userWalletInfo,
            isAccountsMode: isAccountsMode,
            routable: routable
        )

        let mapper = TransactionHistoryMapper(
            currencySymbol: walletModel.tokenItem.currencySymbol,
            addressesProvider: walletModel,
            showSign: true,
            isToken: walletModel.tokenItem.isToken
        )
        let resolver = SubtitleOwnerResolver(
            blockchain: walletModel.tokenItem.blockchain,
            currentUserWalletId: userWalletInfo.id,
            isAccountsMode: isAccountsMode
        )

        subscribe(
            id: id,
            publisher: walletModel.transactionHistoryPublisher,
            context: context,
            mapper: mapper,
            resolver: resolver
        )
    }

    var blocks: [TransactionDetailsBlock] {
        guard isSuccessBannerDismissed else { return rawBlocks }
        return rawBlocks.filter { !Self.isSuccessBanner($0) }
    }

    private var rawBlocks: [TransactionDetailsBlock] {
        guard let content else { return [] }
        return Self.rawBlocks(for: content)
    }

    private func subscribe(
        id: TransactionRecord.ID,
        publisher: AnyPublisher<WalletModelTransactionHistoryState, Never>,
        context: TransactionDetailsContext,
        mapper: TransactionHistoryMapper,
        resolver: SubtitleOwnerResolver
    ) {
        let content = publisher
            .compactMap { state -> TransactionRecord? in
                guard case .loaded(let items) = state else { return nil }
                return items.first { record in
                    if record.id == id {
                        return true
                    }

                    guard let expressTxId = record.expressTxId else {
                        return false
                    }

                    return ExpressSyntheticTxHelper(txId: expressTxId).isMatchingTxIdentifier(id.hash)
                }
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .map { record in
                TransactionDetailsFactory.reduce(
                    transaction: mapper.mapTransactionViewModel(record, subtitleOwnerResolver: resolver),
                    record: record,
                    context: context
                )
            }
            .share()

        content
            .withWeakCaptureOf(self)
            .sink { viewModel, result in
                viewModel.header = result.header
                viewModel.content = result.content
            }
            .store(in: &bag)

        // The success banner is only meaningful as a live transition: a transaction that's already finished when
        // the sheet opens must never flash it, while one that finishes while open shows it briefly, then hides.
        let hasSuccessBanner = content
            .map { Self.rawBlocks(for: $0.content).contains(where: Self.isSuccessBanner) }
            .share()

        // Already finished on the first record → suppress at once.
        hasSuccessBanner
            .first()
            .filter { $0 }
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in viewModel.isSuccessBannerDismissed = true }
            .store(in: &bag)

        // Appears on a later record (live transition) → keep it up briefly, then hide.
        hasSuccessBanner
            .dropFirst()
            .removeDuplicates()
            .filter { $0 }
            .delay(for: .seconds(2), scheduler: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in viewModel.isSuccessBannerDismissed = true }
            .store(in: &bag)
    }

    private static func rawBlocks(for content: Content) -> [TransactionDetailsBlock] {
        switch content {
        case .generic(let data): data.blocks
        case .swap(let viewModel): viewModel.blocks
        case .onramp(let viewModel): viewModel.blocks
        case .yield(let data): data.blocks
        }
    }

    private static func isSuccessBanner(_ block: TransactionDetailsBlock) -> Bool {
        guard case .statusBanner(let data) = block else { return false }
        return data.kind == .success
    }

    enum Content {
        case generic(TransactionDetailsGenericOperationViewData)
        case swap(TransactionDetailsSwapViewData)
        case onramp(TransactionDetailsOnrampViewData)
        case yield(TransactionDetailsYieldViewData)
    }
}

protocol TransactionDetailsRoutable: AnyObject {
    func openTransactionDetailsURL(_ url: URL)
    func shareFromTransactionDetails(_ text: String)
    func closeTransactionDetails()
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
