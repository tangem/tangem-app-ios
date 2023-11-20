//
//  ExpressProvidersBottomSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemSwapping

final class ExpressProvidersBottomSheetViewModel: ObservableObject, Identifiable {
    // MARK: - ViewState

    @Published var providerViewModels: [ProviderRowViewModel] = []

    // MARK: - Dependencies

    private var selectedProviderId: Int?
    private let quotes: [ExpectedQuote]

    private let balanceFormatter: BalanceFormatter
    private unowned let expressInteractor: ExpressInteractor
    private unowned let coordinator: ExpressProvidersBottomSheetRoutable

    private var bag: Set<AnyCancellable> = []

    init(
        input: InputModel,
        balanceFormatter: BalanceFormatter = .init(),
        expressInteractor: ExpressInteractor,
        coordinator: ExpressProvidersBottomSheetRoutable
    ) {
        selectedProviderId = input.selectedProviderId
        quotes = input.quotes

        self.balanceFormatter = balanceFormatter
        self.expressInteractor = expressInteractor
        self.coordinator = coordinator

        setupView()
    }

    func setupView() {
        updateView(quotes: quotes)
    }

    func updateView(quotes: [ExpectedQuote]) {
        providerViewModels = quotes.map { quote in
            mapToProviderRowViewModel(quote: quote)
        }
    }

    func mapToProviderRowViewModel(quote: ExpectedQuote) -> ProviderRowViewModel {
        let provider = quote.provider
        let detailsType: ProviderRowViewModel.DetailsType? = selectedProviderId == provider.id ? .selected : .none

        let viewProvider = ProviderRowViewModel.Provider(
            iconURL: provider.url,
            name: provider.name,
            type: provider.type.rawValue.uppercased()
        )

        let subtitles: [ProviderRowViewModel.Subtitle] = {
            switch quote.state {
            case .quote(let expressQuote):
                if let destination = expressInteractor.getDestination() {
                    let currencyCode = destination.tokenItem.currencySymbol
                    let formatted = balanceFormatter.formatCryptoBalance(expressQuote.expectAmount, currencyCode: currencyCode)
                    return [.text(formatted)]
                }

                return [.text(ExpressInteractorError.destinationNotFound.localizedDescription)]

            case .tooSmallAmount(let minAmount):
                let sender = expressInteractor.getSender()
                let currencyCode = sender.tokenItem.currencySymbol
                let formatted = balanceFormatter.formatCryptoBalance(minAmount, currencyCode: currencyCode)

                return [.text("Min amount: \(formatted)")]

            case .error(let string):
                return [.text("Error: \(string)")]
            case .notAvailable:
                return [.text("Not available for this pair")]
            }
        }()

        return ProviderRowViewModel(
            provider: viewProvider,
            isDisabled: !quote.isAvailable,
            badge: provider.type == .dex ? .permissionNeeded : .none,
            subtitles: subtitles,
            detailsType: detailsType,
            tapAction: { [weak self] in
                self?.selectedProviderId = provider.id
                self?.expressInteractor.updateProvider(provider: provider)
                self?.coordinator.closeExpressProvidersBottomSheet()
            }
        )
    }
}

extension ExpressProvidersBottomSheetViewModel {
    struct InputModel {
        let selectedProviderId: Int?
        let quotes: [ExpectedQuote]
    }
}
