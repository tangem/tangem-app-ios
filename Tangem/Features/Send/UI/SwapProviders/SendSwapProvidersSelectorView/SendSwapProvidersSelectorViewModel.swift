//
//  SendSwapProvidersSelectorViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress
import TangemUI
import TangemFoundation

class SendSwapProvidersSelectorViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter
    @Injected(\.ukGeoDefiner) private var ukGeoDefiner: UKGeoDefiner

    // MARK: - ViewState

    @Published var ukNotificationInput: NotificationViewInput?
    @Published var providerViewModels: [SendSwapProvidersSelectorProviderViewData] = []
    @Published var selectedProvider: ExpressAvailableProvider?

    // MARK: - Dependencies

    private weak var input: SendSwapProvidersInput?
    private weak var output: SendSwapProvidersOutput?
    private weak var receiveTokenInput: SendReceiveTokenInput?

    private let tokenItem: TokenItem
    private let expressProviderFormatter: ExpressProviderFormatter
    private let priceChangeFormatter: PriceChangeFormatter
    private let analyticsLogger: SendSwapProvidersAnalyticsLogger

    private var providers: [ExpressAvailableProvider] = []
    private var bag: Set<AnyCancellable> = []

    init(
        input: SendSwapProvidersInput,
        output: SendSwapProvidersOutput,
        receiveTokenInput: SendReceiveTokenInput,
        tokenItem: TokenItem,
        expressProviderFormatter: ExpressProviderFormatter,
        priceChangeFormatter: PriceChangeFormatter,
        analyticsLogger: SendSwapProvidersAnalyticsLogger
    ) {
        self.input = input
        self.output = output
        self.receiveTokenInput = receiveTokenInput
        self.tokenItem = tokenItem
        self.expressProviderFormatter = expressProviderFormatter
        self.priceChangeFormatter = priceChangeFormatter
        self.analyticsLogger = analyticsLogger

        bind()
    }

    func isSelected(_ providerId: String) -> BindingValue<Bool> {
        .init(root: self, default: false) { root in
            root.selectedProvider?.provider.id == providerId
        } set: { root, isSelected in
            if let provider = root.providers.first(where: { $0.provider.id == providerId }) {
                root.selectedProvider = provider
                root.userDidTap(provider: provider)
            }
        }
    }

    @MainActor
    func dismiss() {
        floatingSheetPresenter.removeActiveSheet()
    }
}

// MARK: - Private

private extension SendSwapProvidersSelectorViewModel {
    func bind() {
        input?
            .expressProvidersPublisher
            .withWeakCaptureOf(self)
            .sink { $0.updateView(providers: $1) }
            .store(in: &bag)

        input?
            .selectedExpressProviderPublisher
            .receiveOnMain()
            .assign(to: &$selectedProvider)
    }

    private func updateView(providers: [ExpressAvailableProvider]) {
        runTask(in: self) { @MainActor viewModel in
            viewModel.providers = providers
            viewModel.showFCAWarningIfNeeded(providers: providers.map(\.provider))
            viewModel.providerViewModels = await viewModel.prepareProviderRows(providers: providers)
        }
    }

    private func prepareProviderRows(providers: [ExpressAvailableProvider]) async -> [SendSwapProvidersSelectorProviderViewData] {
        typealias SortableProvider = (priority: ExpressAvailableProvider.Priority, amount: Decimal)

        let viewModels: [SendSwapProvidersSelectorProviderViewData] = await providers
            .asyncSorted(
                sort: { (firstProvider: SortableProvider, secondProvider: SortableProvider) in
                    if firstProvider.priority == secondProvider.priority {
                        return firstProvider.amount > secondProvider.amount
                    } else {
                        return firstProvider.priority > secondProvider.priority
                    }
                },
                by: { provider in
                    async let priority = provider.getPriority()
                    async let expectedAmount = provider.getState().quote?.expectAmount ?? 0
                    return await (priority, expectedAmount)
                }
            )
            .asyncCompactMap { provider in
                guard provider.isAvailable else {
                    return nil
                }

                // If the provider `isSelected` we are forced to show it anyway
                let isSelected = selectedProvider?.provider.id == provider.provider.id
                let isAvailableToShow = await !provider.getState().isError

                guard isSelected || isAvailableToShow else {
                    return nil
                }

                return await mapToSendSwapProvidersSelectorProviderViewData(availableProvider: provider)
            }

        return viewModels
    }

    func mapToSendSwapProvidersSelectorProviderViewData(availableProvider: ExpressAvailableProvider) async -> SendSwapProvidersSelectorProviderViewData {
        let senderCurrencyCode = tokenItem.currencySymbol
        let destinationCurrencyCode = receiveTokenInput?.receiveToken.tokenItem.currencySymbol
        var subtitles: [ProviderRowViewModel.Subtitle] = []

        let state = await availableProvider.getState()
        subtitles.append(
            expressProviderFormatter.mapToRateSubtitle(
                state: state,
                senderCurrencyCode: senderCurrencyCode,
                destinationCurrencyCode: destinationCurrencyCode,
                option: .exchangeReceivedAmount
            )
        )

        let providerBadge = await expressProviderFormatter.mapToBadge(availableProvider: availableProvider)
        let badge: SendSwapProvidersSelectorProviderViewData.Badge? = switch providerBadge {
        case .none: .none
        case .fcaWarning: .fcaWarning
        case .permissionNeeded: .permissionNeeded
        case .bestRate: .bestRate
        }

        if let percentSubtitle = await makePercentSubtitle(provider: availableProvider) {
            subtitles.append(percentSubtitle)
        }

        let provider = availableProvider.provider
        return SendSwapProvidersSelectorProviderViewData(
            id: provider.id,
            title: provider.name,
            providerIcon: provider.imageURL,
            providerType: provider.type.title,
            isDisabled: state.quote == nil,
            badge: badge,
            subtitles: subtitles
        )
    }

    func userDidTap(provider: ExpressAvailableProvider) {
        // Cancel subscription that view do not jump
        analyticsLogger.logSendSwapProvidersChosen(provider: provider.provider)
        output?.userDidSelect(provider: provider)
        Task { @MainActor in dismiss() }
    }

    func makePercentSubtitle(provider: ExpressAvailableProvider) async -> ProviderRowViewModel.Subtitle? {
        // For selectedProvider we don't add percent badge
        guard selectedProvider?.provider.id != provider.provider.id else {
            return nil
        }

        guard let quote = await provider.getState().quote,
              let selectedRate = await selectedProvider?.getState().quote?.rate else {
            return nil
        }

        let changePercent = quote.rate / selectedRate - 1
        let result = priceChangeFormatter.formatFractionalValue(changePercent, option: .express)
        return .percent(result.formattedText, signType: result.signType)
    }

    private func showFCAWarningIfNeeded(providers: [ExpressProvider]) {
        let allProviderIds = providers.map { $0.id }

        // Display FCA notification if the providers list contains FCA restriction for any provider
        let isRestrictableFCAIncluded = allProviderIds.contains(where: {
            ExpressConstants.expressProvidersFCAWarningList.contains($0)
        })

        if ukGeoDefiner.isUK, isRestrictableFCAIncluded {
            ukNotificationInput = NotificationsFactory().buildNotificationInput(for: ExpressProvidersListEvent.fcaWarningList)
        } else {
            ukNotificationInput = nil
        }
    }
}
