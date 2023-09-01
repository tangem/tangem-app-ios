//
//  TokenItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk
import SwiftUI

typealias WalletModelId = Int

final class TokenItemViewModel: ObservableObject, Identifiable {
    let id: WalletModelId

    @Published var balanceCrypto: LoadableTextView.State = .loading
    @Published var balanceFiat: LoadableTextView.State = .loading
    @Published var priceChangeState: TokenPriceChangeView.State = .loading
    @Published var missingDerivation: Bool = false
    @Published var networkUnreachable: Bool = false
    @Published var hasPendingTransactions: Bool = false

    var name: String { tokenIcon.name }
    var imageURL: URL? { tokenIcon.imageURL }
    var blockchainIconName: String? { tokenIcon.blockchainIconName }
    var hasMonochromeIcon: Bool { networkUnreachable || missingDerivation || tokenItem.blockchain.isTestnet }
    var errorMessage: String? {
        // Don't forget to add check in trailing item in `TokenItemView` when adding new error here
        if missingDerivation {
            return Localization.commonNoAddress
        }

        if networkUnreachable {
            return Localization.commonUnreachable
        }

        return nil
    }

    private let tokenIcon: TokenIconInfo
    private let tokenItem: TokenItem
    private let tokenTapped: (WalletModelId) -> Void
    private weak var infoProvider: TokenItemInfoProvider?

    private var percentFormatter = PercentFormatter()
    private var bag = Set<AnyCancellable>()

    init(
        id: Int,
        tokenIcon: TokenIconInfo,
        tokenItem: TokenItem,
        tokenTapped: @escaping (WalletModelId) -> Void,
        infoProvider: TokenItemInfoProvider
    ) {
        self.id = id
        self.tokenIcon = tokenIcon
        self.tokenItem = tokenItem
        self.tokenTapped = tokenTapped
        self.infoProvider = infoProvider

        bind()
    }

    func tapAction() {
        tokenTapped(id)
    }

    private func bind() {
        infoProvider?.tokenItemStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                guard let self else { return }

                switch newState {
                case .noDerivation:
                    missingDerivation = true
                    networkUnreachable = false
                    updateBalances()
                    updatePriceChange()
                case .networkError:
                    missingDerivation = false
                    networkUnreachable = true
                case .notLoaded:
                    missingDerivation = false
                    networkUnreachable = false
                case .loaded, .noAccount:
                    missingDerivation = false
                    networkUnreachable = false
                    updateBalances()
                    updatePriceChange()
                case .loading:
                    break
                }

                updatePendingTransactionsStateIfNeeded()
            }
            .store(in: &bag)
    }

    private func updatePendingTransactionsStateIfNeeded() {
        guard let infoProvider = infoProvider else { return }

        hasPendingTransactions = infoProvider.hasPendingTransactions
    }

    private func updateBalances() {
        guard let infoProvider = infoProvider else { return }

        balanceCrypto = .loaded(text: infoProvider.balance)
        balanceFiat = .loaded(text: infoProvider.fiatBalance)
    }

    private func updatePriceChange() {
        guard let quote = infoProvider?.quote else {
            priceChangeState = .noData
            return
        }

        let signType: TokenPriceChangeView.ChangeSignType
        if quote.change > 0 {
            signType = .positive
        } else if quote.change < 0 {
            signType = .negative
        } else {
            signType = .same
        }

        let percent = percentFormatter.percentFormat(value: quote.change)
        priceChangeState = .loaded(signType: signType, text: percent)
    }
}
