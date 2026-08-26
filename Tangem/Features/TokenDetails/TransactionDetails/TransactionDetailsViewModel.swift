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

@MainActor
final class TransactionDetailsViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Injected(\.alertPresenter)
    private var alertPresenter: AlertPresenter

    @Injected(\.ratingProvider) private var ratingProvider: RatingProvider
    @Injected(\.transactionHistoryAuxDataRepository) private var auxDataRepository: TransactionHistoryAuxDataRepository

    @Published private(set) var header: TransactionDetailsHeaderViewData?
    @Published private(set) var content: Content?
    @Published private(set) var presentedFeedback: RatingFeedbackBottomSheetViewModel?

    @Published private var ratingViewModel: RatingViewModel?
    @Published private var isRatingCardVisible = false
    @Published private var isSuccessBannerDismissed = false

    private let walletModel: any WalletModel
    private let userWalletId: UserWalletId
    private let userWalletIdHash: String
    private let context: TransactionDetailsContext

    private let addressBookAnalyticsLogger: AddressBookAnalyticsLogger
    private let addressBookWallet: AddressBookWallet

    private weak var routable: TransactionDetailsRoutable?

    private let swapRatingAvailability = SwapRatingAvailability()

    private var record: TransactionRecord?
    private var ratingSetupTask: Task<Void, Never>?

    private var bag: Set<AnyCancellable> = []

    init(
        id: TransactionRecord.ID,
        walletModel: any WalletModel,
        userWalletInfo: UserWalletInfo,
        isAccountsMode: Bool,
        addressBookManager: AddressBookManager,
        addressBookAnalyticsLogger: AddressBookAnalyticsLogger,
        routable: TransactionDetailsRoutable
    ) {
        self.routable = routable
        self.walletModel = walletModel
        self.addressBookAnalyticsLogger = addressBookAnalyticsLogger
        userWalletId = userWalletInfo.id
        userWalletIdHash = userWalletInfo.id.hashedStringValue
        addressBookWallet = AddressBookWallet(wallet: userWalletInfo, addressBookManager: addressBookManager)

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
            transactionHistoryPublisher: walletModel.transactionHistoryPublisher,
            contactsPublisher: addressBookWallet.addressBookPublisher,
            syncStatePublisher: addressBookWallet.syncStatePublisher,
            context: context,
            mapper: mapper,
            resolver: resolver
        )

        loadAddressBook() // Address book should be loaded as early as possible since it is empty by default
    }

    deinit {
        ratingSetupTask?.cancel()
    }

    var blocks: [TransactionDetailsBlock] {
        guard isSuccessBannerDismissed else { return rawBlocks }
        return rawBlocks.filter { !Self.isSuccessBanner($0) }
    }

    private func setupRatingViewModel(for content: Content?) {
        guard
            ratingSetupTask == nil,
            case .swap(let data) = content,
            let transaction = data.ratingTransaction,
            swapRatingAvailability.isAvailable
        else {
            return
        }

        ratingSetupTask = Task { [weak self] in
            await self?.makeRatingViewModel(for: transaction)
        }
    }

    private func makeRatingViewModel(for transaction: TransactionDetailsSwapViewData.RatingTransaction) async {
        var resolvedName = transaction.providerName

        if resolvedName == nil {
            resolvedName = await auxDataRepository.provider(id: transaction.providerId, branch: .swap)?.name
        }

        guard let providerName = resolvedName else {
            ratingSetupTask = nil
            return
        }

        let ratingViewModel = RatingViewModel(
            model: RatingModel(
                ratingProvider: ratingProvider,
                transaction: RatingModel.Transaction(
                    transactionId: transaction.transactionId,
                    providerName: providerName,
                    txUrl: transaction.txUrl
                ),
                userWalletIdHash: userWalletIdHash
            ),
            feedbackPresenter: self
        )

        ratingViewModel.isCardVisiblePublisher.assign(to: &$isRatingCardVisible)
        self.ratingViewModel = ratingViewModel
    }

    private var rawBlocks: [TransactionDetailsBlock] {
        guard let content else { return [] }

        let blocks = Self.rawBlocks(for: content)

        guard let ratingViewModel, isRatingCardVisible else { return blocks }

        return blocks.flatMap { block in
            if case .tokens = block {
                [block, .rating(ratingViewModel)]
            } else {
                [block]
            }
        }
    }

    private func subscribe(
        id: TransactionRecord.ID,
        transactionHistoryPublisher: some Publisher<WalletModelTransactionHistoryState, Never>,
        contactsPublisher: some Publisher<[AddressBookContact], Never>,
        syncStatePublisher: some Publisher<AddressBookSyncState, Never>,
        context: TransactionDetailsContext,
        mapper: TransactionHistoryMapper,
        resolver: SubtitleOwnerResolver
    ) {
        let recordPublisher = transactionHistoryPublisher
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

        let enrichedRecordPublisher = recordPublisher
            .combineLatest(
                contactsPublisher.removeDuplicates(),
                syncStatePublisher.map(\.isSynced).removeDuplicates()
            )
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .map { viewModel, args in
                let (record, contacts, isAddressBookSynced) = args
                let transaction = mapper.mapTransactionViewModel(record, subtitleOwnerResolver: resolver)

                return (
                    record: record,
                    reduced: TransactionDetailsFactory.reduce(
                        transaction: transaction,
                        record: record,
                        context: context,
                        addContactHelper: viewModel.makeAddContactHelper(
                            for: transaction,
                            contacts: contacts,
                            isAddressBookSynced: isAddressBookSynced
                        )
                    )
                )
            }
            .share(replay: 1)

        enrichedRecordPublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, output in
                viewModel.record = output.record
                viewModel.header = output.reduced.header
                viewModel.content = output.reduced.content
                viewModel.setupRatingViewModel(for: output.reduced.content)
            }
            .store(in: &bag)

        // The success banner is only meaningful as a live transition: a transaction that's already finished when
        // the sheet opens must never flash it (previous == nil → dismiss with no delay), while one that finishes
        // while open shows it, then hides (a false → true transition → dismiss after a short delay).
        enrichedRecordPublisher
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
        case .addContact(let address):
            addContact(address: address)
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
        guard let record, let text = TransactionDetailsMenuFactory.shareText(for: record, context: context) else {
            return
        }

        routable?.shareFromTransactionDetails(text: text)
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
        guard let record, let target = TransactionDetailsFactory.refundTarget(for: record) else {
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

        routable?.openTransactionDetailsDebug(TransactionDetailsDebugInfoFactory.make(for: record))
    }
    #endif

    // MARK: - Address book support

    private func loadAddressBook() {
        runTask(in: self) { viewModel in
            await viewModel.addressBookWallet.addressBookManager.load(silent: true)
        }
    }

    private func makeAddContactHelper(
        for transaction: TransactionViewModel,
        contacts: [AddressBookContact],
        isAddressBookSynced: Bool
    ) -> TransactionDetailsAddContactHelper {
        TransactionDetailsAddContactHelper(
            networkId: AddressBookNetworkID(walletModel.tokenItem.blockchain.networkId),
            contacts: contacts,
            isAddressBookSynced: isAddressBookSynced,
            transactionType: transaction.transactionType,
            interactionAddress: transaction.interactionAddress
        )
    }

    private func addContact(address: String) {
        addressBookAnalyticsLogger.logAddContactTapped(userWalletId: userWalletId, source: .transactionDetails)

        // BSDK transactions don't carry memo information, so we can't prefill it - hence `nil`
        let entry = AddressBookEntryDraft(address: address, blockchain: walletModel.tokenItem.blockchain, memo: nil)
        routable?.openAddContactFromTransactionDetails(addressBookWallet: addressBookWallet, prefilledEntries: [entry])
    }

    // MARK: - Blocks

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
}

// MARK: - Auxiliary types

extension TransactionDetailsViewModel {
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
        case addContact(address: String)
        case close
        #if INTERNAL || DEBUG
        case debug
        #endif
    }

    private enum RefundTokenError: Error {
        case targetNotResolved
    }
}

// MARK: - RatingFeedbackPresenter

extension TransactionDetailsViewModel: RatingFeedbackPresenter {
    func present(_ viewModel: RatingFeedbackBottomSheetViewModel) {
        presentedFeedback = viewModel
    }

    func dismiss() {
        presentedFeedback = nil
    }
}
