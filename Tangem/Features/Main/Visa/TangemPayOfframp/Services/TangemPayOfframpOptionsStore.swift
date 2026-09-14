//
//  TangemPayOfframpOptionsStore.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemAssets
import TangemFoundation
import TangemPay
import TangemVisa

final class TangemPayOfframpOptionsStore {
    var state: State {
        stateSubject.value
    }

    var statePublisher: some Publisher<State, Never> {
        stateSubject
    }

    private(set) var loadTask: Task<Void, Never>?

    private let optionsRepository: any TangemPayOfframpOptionsRepository
    private let accountTokensProvider: () async -> [TangemPayAccountToken]
    private let stateSubject = CurrentValueSubject<State, Never>(.loading)

    init(
        optionsRepository: any TangemPayOfframpOptionsRepository,
        accountTokensProvider: @escaping () async -> [TangemPayAccountToken]
    ) {
        self.optionsRepository = optionsRepository
        self.accountTokensProvider = accountTokensProvider
    }

    func load() {
        guard loadTask == nil else { return }

        loadTask = Task { @MainActor [weak self] in
            await self?.loadOptions()
        }
    }
}

// MARK: - Loading

private extension TangemPayOfframpOptionsStore {
    @MainActor
    func loadOptions() async {
        do {
            let options = try await optionsRepository.options()
            let accountTokens = await accountTokensProvider()

            stateSubject.send(
                .loaded(
                    Options(
                        tokens: Self.makeTokenItems(from: accountTokens, sources: options.sources),
                        rails: Self.makeRailItems(from: options.destinations)
                    )
                )
            )
        } catch {
            VisaLogger.error("Failed to load Tangem Pay off-ramp options", error: error)
            stateSubject.send(.loaded(.empty))
        }
    }
}

// MARK: - State

extension TangemPayOfframpOptionsStore {
    enum State {
        case loading
        case loaded(Options)

        var options: Options? {
            switch self {
            case .loading:
                nil
            case .loaded(let options):
                options
            }
        }
    }

    struct Options: Equatable {
        let tokens: [TransferInputTokenItem]
        let rails: [TransferInputRailItem]

        static let empty = Options(tokens: [], rails: [])

        var availableTokens: [TransferInputTokenItem] {
            tokens.filter(\.isOfframpAvailable)
        }

        var hasAvailableTokens: Bool {
            availableTokens.isNotEmpty
        }

        var defaultToken: TransferInputTokenItem? {
            availableTokens.first
        }

        var defaultRail: TransferInputRailItem? {
            rails.first
        }
    }
}

// MARK: - Mapping

extension TangemPayOfframpOptionsStore {
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
                ),
                feeAmount: destination.fee.amount
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

// MARK: - Constants

private extension TangemPayOfframpOptionsStore {
    enum Constants {
        static let feeFractionDigits = 2

        static let feeFormattingOptions = BalanceFormattingOptions(
            minFractionDigits: 0,
            maxFractionDigits: feeFractionDigits,
            formatEpsilonAsLowestRepresentableValue: false,
            roundingType: .default(roundingMode: .plain, scale: feeFractionDigits)
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
