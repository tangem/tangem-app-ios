//
//  TransactionDetailsViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import Combine
import CombineExt
import BlockchainSdk
import TangemExpress
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemUI
import struct TangemUIUtils.AlertBinder

final class TransactionDetailsViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Injected(\.alertPresenter)
    private var alertPresenter: any AlertPresenter

    @Published private(set) var header: TransactionDetailsHeaderViewData?
    @Published private(set) var content: Content?

    @Published private var isSuccessBannerDismissed = false

    private weak var routable: (any TransactionDetailsRoutable)?
    private let walletModel: any WalletModel
    private let userWalletId: UserWalletId
    private let context: TransactionDetailsContext

    private var record: TransactionRecord?
    private var bag = Set<AnyCancellable>()

    init(
        id: TransactionRecord.ID,
        walletModel: any WalletModel,
        userWalletInfo: UserWalletInfo,
        isAccountsMode: Bool,
        routable: TransactionDetailsRoutable
    ) {
        self.routable = routable
        self.walletModel = walletModel
        userWalletId = userWalletInfo.id

        let context = TransactionDetailsContext(
            walletModel: walletModel,
            userWalletInfo: userWalletInfo,
            isAccountsMode: isAccountsMode
        )
        self.context = context

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
        let output = publisher
            .compactMap { state -> TransactionRecord? in
                guard case .loaded(let items) = state else { return nil }
                return items.first { record in
                    if record.id == id {
                        return true
                    }

                    guard let expressTxId = record.expressExtraInfo?.txId else {
                        return false
                    }

                    return ExpressSyntheticTxHelper(txId: expressTxId).isMatchingTxIdentifier(id.hash)
                }
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .map { record in
                (
                    record: record,
                    reduced: TransactionDetailsFactory.reduce(
                        transaction: mapper.mapTransactionViewModel(record, subtitleOwnerResolver: resolver),
                        record: record,
                        context: context
                    )
                )
            }
            .share(replay: 1)

        output
            .withWeakCaptureOf(self)
            .sink { viewModel, output in
                viewModel.record = output.record
                viewModel.header = output.reduced.header
                viewModel.content = output.reduced.content
            }
            .store(in: &bag)

        // The success banner is only meaningful as a live transition: a transaction that's already finished when
        // the sheet opens must never flash it (previous == nil → dismiss with no delay), while one that finishes
        // while open shows it, then hides (a false → true transition → dismiss after a short delay).
        output
            .map { output in
                Self.rawBlocks(for: output.reduced.content).contains(where: Self.isSuccessBanner)
            }
            .removeDuplicates()
            .withPrevious()
            .filter { $0.current }
            .flatMap { previous, _ -> AnyPublisher<Void, Never> in
                guard previous != nil else {
                    // First record already carries the banner → suppress synchronously, without a flash.
                    return Just(()).eraseToAnyPublisher()
                }

                return Just(())
                    .delay(for: .seconds(2), scheduler: DispatchQueue.main)
                    .eraseToAnyPublisher()
            }
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.isSuccessBannerDismissed = true
            }
            .store(in: &bag)
    }

    // MARK: - Actions

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .openURL(let url):
            routable?.openTransactionDetailsURL(url)
        case .share:
            share()
        case .close:
            routable?.closeTransactionDetails()
        case .copy(let value, let toast):
            copy(value, toast: toast)
        case .openRefundToken:
            openRefundToken()
        #if INTERNAL || DEBUG
        case .debug:
            openDebug()
        #endif
        }
    }

    private func copy(_ value: String, toast text: String) {
        UIPasteboard.general.string = value
        FeedbackGenerator.selectionChanged()

        Toast(
            view: TangemSnackbar(title: text)
                .icon(DesignSystem.Icons.Checkmark.regular20)
                .iconColor(Color.Tangem.Graphic.Status.accent)
        )
        .present(layout: .top(padding: 14), type: .temporary())
    }

    private func share() {
        guard let item = TransactionDetailsFactory.shareItem(for: record, context: context) else {
            return
        }

        routable?.shareFromTransactionDetails(item)
    }

    private func openRefundToken() {
        Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                let result = try await findRefundTokenWalletModel()
                routable?.openTokenFromTransactionDetails(walletModel: result.walletModel, userWalletModel: result.userWalletModel)
            } catch {
                AppLogger.error("Unable to open the refund token", error: error)
                alertPresenter.present(alert: AlertBuilder.makeOkErrorAlert(message: Localization.commonUnknownError))
            }
        }
    }

    private func findRefundTokenWalletModel() async throws -> WalletModelFinder.Result {
        guard let target = TransactionDetailsFactory.refundTarget(for: record) else {
            throw RefundTokenError.targetNotResolved
        }

        let tokenItem = target.tokenItem

        if let receiver = try? WalletModelFinder.findWalletModel(
            address: target.address,
            networkId: tokenItem.blockchain.networkId,
            isTestnet: tokenItem.blockchain.isTestnet,
            shallowMatchingTokenItem: tokenItem
        ) {
            return receiver
        }

        if let own = try? WalletModelFinder.findWalletModel(userWalletId: userWalletId, shallowMatchingTokenItem: tokenItem) {
            return own
        }

        // The refund token isn't in the current wallet's portfolio yet, so it only becomes findable after being added.
        _ = try await walletModel.account?.userTokensManager.add(tokenItem)

        return try WalletModelFinder.findWalletModel(userWalletId: userWalletId, shallowMatchingTokenItem: tokenItem)
    }

    #if INTERNAL || DEBUG
    private func openDebug() {
        guard let record else { return }

        routable?.openTransactionDetailsDebug(TransactionDetailsFactory.debugInfo(for: record))
    }
    #endif

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

    enum ViewAction: Equatable {
        case openURL(URL)
        case share
        case copy(value: String, toast: String)
        case openRefundToken
        case close
        #if INTERNAL || DEBUG
        case debug
        #endif
    }

    private enum RefundTokenError: Error {
        case targetNotResolved
    }
}

protocol TransactionDetailsRoutable: AnyObject {
    func openTransactionDetailsURL(_ url: URL)
    func shareFromTransactionDetails(_ item: TransactionDetailsShareItem)
    func openTokenFromTransactionDetails(walletModel: any WalletModel, userWalletModel: UserWalletModel)
    #if INTERNAL || DEBUG
    func openTransactionDetailsDebug(_ info: TransactionDetailsDebugInfo)
    #endif
    func closeTransactionDetails()
}

enum TransactionDetailsShareItem: Equatable {
    case text(String)
    case url(URL)
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
