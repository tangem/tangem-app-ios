//
//  TransferInputViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemAssets
import TangemFoundation
import TangemPay
import TangemVisa

@MainActor
final class TransferInputViewModel: ObservableObject {
    let amountFieldViewModel = DecimalNumberTextFieldViewModel(
        maximumFractionDigits: Constants.fractionDigits,
        locale: Locale(identifier: Constants.localeIdentifier)
    )

    @Published private(set) var tokenItems: [TransferInputTokenItem] = []
    @Published private(set) var railItems: [TransferInputRailItem] = []
    @Published private(set) var isLoadingTokens = true
    @Published private(set) var selectedTokenID: TransferInputTokenItem.ID?
    @Published private(set) var selectedRail: TangemPayBankAccountRail?
    @Published private(set) var amountState: TransferInputAmountState = .empty
    @Published private(set) var didFailToLoadOptions = false
    @Published private(set) var isRetrying = false
    @Published var isTokenModalPresented = false
    @Published var isRailModalPresented = false

    let title: String
    let stepSubtitle: String?

    private let orderBuilder: TangemPayOfframpOrderBuilder
    private let optionsRepository: any TangemPayOfframpOptionsRepository
    private let accountTokensProvider: () async -> [TangemPayAccountToken]
    private let output: (Output) -> Void

    private var loadTask: Task<Void, Never>?
    private var bag: Set<AnyCancellable> = []

    init(
        orderBuilder: TangemPayOfframpOrderBuilder,
        optionsRepository: any TangemPayOfframpOptionsRepository,
        accountTokensProvider: @escaping () async -> [TangemPayAccountToken],
        title: String,
        stepSubtitle: String?,
        output: @escaping (Output) -> Void
    ) {
        self.orderBuilder = orderBuilder
        self.optionsRepository = optionsRepository
        self.accountTokensProvider = accountTokensProvider
        self.title = title
        self.stepSubtitle = stepSubtitle
        self.output = output

        restore()
        bind()
    }

    var contentState: TransferInputContentView.State {
        TransferInputContentView.State(
            tokenRow: tokenRow,
            rail: selectedRailItem,
            amountErrorMessage: amountState.errorMessage,
            isErrorBannerVisible: didFailToLoadOptions && !isRetrying,
            isContinueEnabled: isContinueEnabled
        )
    }

    func onAppear() {
        guard loadTask == nil else { return }

        loadTask = Task { @MainActor [weak self] in
            await self?.load()
        }
    }

    func handle(_ action: TransferInputContentView.Action) {
        switch action {
        case .tokenTap:
            isTokenModalPresented = true
        case .railTap:
            isRailModalPresented = true
        case .maxTap:
            applyMaxAmount()
        case .retryTap:
            retry()
        case .continueTap:
            submit()
        }
    }

    func onCloseTap() {
        output(.close)
    }
}

// MARK: - Derived state

private extension TransferInputViewModel {
    var selectedToken: TransferInputTokenItem? {
        tokenItems.first { $0.id == selectedTokenID }
    }

    var selectedRailItem: TransferInputRailItem? {
        railItems.first { $0.rail == selectedRail }
    }

    var isContinueEnabled: Bool {
        amountState.isValid && selectedToken != nil && selectedRail != nil
    }

    var tokenRow: TransferInputContentView.State.TokenRow {
        if isLoadingTokens {
            return .loading
        }

        guard let selectedToken else {
            return .unavailable
        }

        return .token(selectedToken)
    }
}

// MARK: - Actions

private extension TransferInputViewModel {
    func applyMaxAmount() {
        guard let selectedToken else { return }

        let amount = min(selectedToken.balance, Constants.maxAmount)

        amountFieldViewModel.update(value: amount)
        amountState = Self.validate(amount: amount, balance: selectedToken.balance)
    }

    func submit() {
        guard
            isContinueEnabled,
            let amount = amountFieldViewModel.value,
            let selectedToken,
            let selectedRail
        else {
            return
        }

        orderBuilder.set(amount: amount)
        orderBuilder.set(
            token: TangemPayOfframpTokenSelection(
                chainId: selectedToken.chainId,
                tokenContractAddress: selectedToken.contractAddress
            )
        )
        orderBuilder.set(rail: selectedRail)

        output(.continueWizard)
    }
}

// MARK: - Modal bindings

extension TransferInputViewModel {
    var tokenSelectionBinding: Binding<TransferInputTokenItem.ID?> {
        Binding(
            get: { [weak self] in self?.selectedTokenID },
            set: { [weak self] in self?.selectToken(id: $0) }
        )
    }

    var railSelectionBinding: Binding<TangemPayBankAccountRail?> {
        Binding(
            get: { [weak self] in self?.selectedRail },
            set: { [weak self] in self?.selectRail($0) }
        )
    }
}

// MARK: - Selection

private extension TransferInputViewModel {
    func selectToken(id: TransferInputTokenItem.ID?) {
        guard let item = tokenItems.first(where: { $0.id == id }), item.isOfframpAvailable else {
            return
        }

        selectedTokenID = item.id
        isTokenModalPresented = false
        revalidate()
    }

    func selectRail(_ rail: TangemPayBankAccountRail?) {
        guard let rail, railItems.contains(where: { $0.rail == rail }) else { return }

        selectedRail = rail
        isRailModalPresented = false
    }
}

// MARK: - Loading

private extension TransferInputViewModel {
    func load() async {
        var sources: [TangemPayBankOfframpOptionsResponse.Source] = []

        do {
            let options = try await optionsRepository.options()

            sources = options.sources
            railItems = Self.makeRailItems(from: options.destinations)
            didFailToLoadOptions = false
        } catch {
            VisaLogger.error("Failed to load Tangem Pay off-ramp options", error: error)

            railItems = []
            didFailToLoadOptions = true
        }

        applyDefaultRailSelection()

        let accountTokens = await accountTokensProvider()
        tokenItems = Self.makeTokenItems(from: accountTokens, sources: sources)
        isLoadingTokens = false

        applyDefaultTokenSelection()
        revalidate()

        isRetrying = false
    }

    func retry() {
        guard !isRetrying else { return }

        isRetrying = true
        isLoadingTokens = true

        loadTask?.cancel()
        loadTask = Task { @MainActor [weak self] in
            await self?.load()
        }
    }

    func applyDefaultRailSelection() {
        guard selectedRail == nil || !railItems.contains(where: { $0.rail == selectedRail }) else {
            return
        }

        selectedRail = railItems.first?.rail
    }

    func applyDefaultTokenSelection() {
        let available = tokenItems.filter(\.isOfframpAvailable)

        guard selectedTokenID == nil || !available.contains(where: { $0.id == selectedTokenID }) else {
            return
        }

        selectedTokenID = available.first?.id
    }
}

// MARK: - Restore

private extension TransferInputViewModel {
    func restore() {
        if let amount = orderBuilder.amount {
            amountFieldViewModel.update(value: amount)
        }

        selectedRail = orderBuilder.rail

        if let token = orderBuilder.token {
            selectedTokenID = Self.tokenID(chainId: token.chainId, contractAddress: token.tokenContractAddress)
        }
    }

    func bind() {
        amountFieldViewModel
            .valuePublisher()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.revalidate()
            }
            .store(in: &bag)
    }

    func revalidate() {
        amountState = Self.validate(
            amount: amountFieldViewModel.value,
            balance: selectedToken?.balance
        )
    }
}

// MARK: - Validation

private extension TransferInputViewModel {
    static func validate(amount: Decimal?, balance: Decimal?) -> TransferInputAmountState {
        guard let amount, amount > 0 else {
            return .empty
        }

        guard amount >= Constants.minAmount, amount <= Constants.maxAmount else {
            return .outOfRange(min: Constants.minAmount, max: Constants.maxAmount)
        }

        if let balance, amount > balance {
            return .notEnoughFunds
        }

        return .valid
    }
}

// MARK: - Mapping

private extension TransferInputViewModel {
    static func tokenID(chainId: Int, contractAddress: String) -> String {
        "\(chainId)-\(contractAddress.lowercased())"
    }

    static func makeRailItems(
        from destinations: [TangemPayBankOfframpOptionsResponse.Destination]
    ) -> [TransferInputRailItem] {
        destinations.map { destination in
            TransferInputRailItem(
                rail: destination.rail,
                icon: destination.rail.icon,
                title: destination.fee.name?.nilIfEmpty ?? destination.rail.displayName,
                etaText: etaText(for: destination.eta),
                feeText: BalanceFormatter().formatFiatBalance(
                    destination.fee.amount,
                    currencyCode: destination.fee.currency?.nilIfEmpty ?? TangemPayUtilities.fiatItem.currencyCode,
                    formattingOptions: Constants.feeFormattingOptions
                )
            )
        }
    }

    static func etaText(for eta: TangemPayBankOfframpOptionsResponse.ETA) -> String {
        if eta.maxDays <= 0 {
            // [REDACTED_TODO_COMMENT]
            return "Same business day"
        }

        if eta.minDays == eta.maxDays {
            // [REDACTED_TODO_COMMENT]
            return "\(eta.maxDays) business \(eta.maxDays == 1 ? "day" : "days")"
        }

        // [REDACTED_TODO_COMMENT]
        return "\(eta.minDays)-\(eta.maxDays) business days"
    }

    static func makeTokenItems(
        from accountTokens: [TangemPayAccountToken],
        sources: [TangemPayBankOfframpOptionsResponse.Source]
    ) -> [TransferInputTokenItem] {
        let offrampable = Set(
            sources.flatMap { source in
                source.tokens.map { tokenID(chainId: source.chainId, contractAddress: $0.tokenContractAddress) }
            }
        )

        let items: [TransferInputTokenItem] = accountTokens.compactMap { accountToken in
            guard
                let chainId = accountToken.chainId,
                let contractAddress = accountToken.tokenItem.contractAddress?.nilIfEmpty,
                let balance = accountToken.availableForWithdrawal,
                balance > 0
            else {
                return nil
            }

            let id = tokenID(chainId: chainId, contractAddress: contractAddress)

            return TransferInputTokenItem(
                id: id,
                tokenIconInfo: TokenIconInfoBuilder().build(from: accountToken.tokenItem, isCustom: false),
                symbol: accountToken.tokenItem.currencySymbol,
                networkName: accountToken.tokenItem.blockchain.displayName,
                balance: balance,
                balanceText: BalanceFormatter().formatFiatBalance(
                    balance,
                    currencyCode: TangemPayUtilities.fiatItem.currencyCode
                ),
                chainId: chainId,
                contractAddress: contractAddress,
                isOfframpAvailable: offrampable.contains(id)
            )
        }

        return sortedSymbolMajor(items)
    }

    static func sortedSymbolMajor(_ items: [TransferInputTokenItem]) -> [TransferInputTokenItem] {
        let canonicalSymbol = TangemPayUtilities.usdcTokenItem.currencySymbol

        var symbolRank: [String: Int] = [:]

        for symbol in items.map(\.symbol) where symbolRank[symbol] == nil {
            symbolRank[symbol] = symbolRank.count
        }

        return items.enumerated()
            .sorted { lhs, rhs in
                let lhsIsCanonical = lhs.element.symbol == canonicalSymbol
                let rhsIsCanonical = rhs.element.symbol == canonicalSymbol

                guard lhsIsCanonical == rhsIsCanonical else {
                    return lhsIsCanonical
                }

                let lhsRank = symbolRank[lhs.element.symbol] ?? .max
                let rhsRank = symbolRank[rhs.element.symbol] ?? .max

                guard lhsRank == rhsRank else {
                    return lhsRank < rhsRank
                }

                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }
}

// MARK: - Output

extension TransferInputViewModel {
    enum Output {
        case continueWizard
        case close
    }
}

// MARK: - Constants

extension TransferInputViewModel {
    enum Constants {
        static let minAmount: Decimal = 1
        static let maxAmount: Decimal = 10_000
        static let fractionDigits = 2
        static let localeIdentifier = "en_US"

        static let feeFormattingOptions = BalanceFormattingOptions(
            minFractionDigits: 0,
            maxFractionDigits: fractionDigits,
            formatEpsilonAsLowestRepresentableValue: false,
            roundingType: .default(roundingMode: .plain, scale: fractionDigits)
        )
    }
}

// MARK: - Rail display name

private extension TangemPayBankAccountRail {
    var displayName: String {
        switch self {
        case .ach: "ACH"
        case .wire: "FedWire"
        }
    }

    var icon: ImageType {
        switch self {
        case .ach: Assets.Visa.railAch
        case .wire: Assets.Visa.railFedwire
        }
    }
}
