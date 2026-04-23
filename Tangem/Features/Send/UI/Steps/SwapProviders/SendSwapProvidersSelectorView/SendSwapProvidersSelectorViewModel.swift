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
    @Injected(\.geoEligibilityService) private var geoEligibilityService: GeoEligibilityService

    // MARK: - ViewState

    @Published var ukNotificationInput: NotificationViewInput?
    @Published var providerViewModels: [SendSwapProvidersSelectorProviderViewData] = []

    // MARK: - Dependencies

    private weak var input: SendSwapProvidersInput?
    private weak var output: SendSwapProvidersOutput?
    private weak var receiveTokenInput: SendReceiveTokenInput?
    private weak var receiveTokenAmountInput: SendReceiveTokenAmountInput?

    private let tokenItem: TokenItem
    private let expressProviderFormatter: ExpressProviderFormatter
    private let priceChangeFormatter: PriceChangeFormatter
    private let analyticsLogger: SendSwapProvidersAnalyticsLogger

    private var bag: Set<AnyCancellable> = []

    init(
        input: SendSwapProvidersInput,
        output: SendSwapProvidersOutput,
        receiveTokenInput: SendReceiveTokenInput,
        receiveTokenAmountInput: SendReceiveTokenAmountInput?,
        tokenItem: TokenItem,
        expressProviderFormatter: ExpressProviderFormatter,
        priceChangeFormatter: PriceChangeFormatter,
        analyticsLogger: SendSwapProvidersAnalyticsLogger
    ) {
        self.input = input
        self.output = output
        self.receiveTokenInput = receiveTokenInput
        self.receiveTokenAmountInput = receiveTokenAmountInput
        self.tokenItem = tokenItem
        self.expressProviderFormatter = expressProviderFormatter
        self.priceChangeFormatter = priceChangeFormatter
        self.analyticsLogger = analyticsLogger

        bind(input: input)
    }

    func isSelected(_ providerId: String) -> BindingValue<Bool> {
        .init(root: self, default: false) { root in
            root.input?.selectedExpressProvider?.value?.provider.id == providerId
        } set: { root, isSelected in
            root.userDidTap(providerId: providerId)
        }
    }

    @MainActor
    func dismiss() {
        floatingSheetPresenter.removeActiveSheet()
    }
}

// MARK: - Private

private extension SendSwapProvidersSelectorViewModel {
    func bind(input: SendSwapProvidersInput) {
        let highPriceImpactPublisher = receiveTokenAmountInput?.highPriceImpactPublisher ?? Just(nil).eraseToAnyPublisher()

        Publishers.CombineLatest3(
            input.selectedExpressProviderPublisher.map { $0?.value },
            input.expressProvidersPublisher,
            highPriceImpactPublisher
        )
        .withWeakCaptureOf(self)
        .map { viewModel, values in
            let (selectedProvider, providers, highPriceImpactValue) = values
            let hasWarning = highPriceImpactValue.map { !$0.level.isNegligible } ?? false
            return viewModel.prepareProviderRows(selectedProvider: selectedProvider, providers: providers, hasHighPriceImpactWarning: hasWarning)
        }
        .receiveOnMain()
        .assign(to: &$providerViewModels)

        input
            .expressProvidersPublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .map { $0.mapToFCAWarningIfNeeded(providers: $1) }
            .assign(to: &$ukNotificationInput)
    }

    private func prepareProviderRows(selectedProvider: ExpressAvailableProvider?, providers: [ExpressAvailableProvider], hasHighPriceImpactWarning: Bool) -> [SendSwapProvidersSelectorProviderViewData] {
        let viewModels: [SendSwapProvidersSelectorProviderViewData] = providers
            .showableProviders(selectedProviderId: selectedProvider?.provider.id, rateType: input?.currentRateType)
            .sortedByPriorityAndQuotes()
            .map { mapToSendSwapProvidersSelectorProviderViewData(selectedProvider: selectedProvider, availableProvider: $0, hasHighPriceImpactWarning: hasHighPriceImpactWarning) }

        return viewModels
    }

    func mapToSendSwapProvidersSelectorProviderViewData(selectedProvider: ExpressAvailableProvider?, availableProvider: ExpressAvailableProvider, hasHighPriceImpactWarning: Bool) -> SendSwapProvidersSelectorProviderViewData {
        let senderCurrencyCode = tokenItem.currencySymbol
        let destinationCurrencyCode = receiveTokenInput?.receiveToken.value?.tokenItem.currencySymbol
        var subtitles: [ProviderRowViewModel.Subtitle] = []

        let state = availableProvider.getState()
        subtitles.append(
            expressProviderFormatter.mapToRateSubtitle(
                state: state,
                senderCurrencyCode: senderCurrencyCode,
                destinationCurrencyCode: destinationCurrencyCode,
                option: .exchangeReceivedAmount
            )
        )

        let providerBadge = expressProviderFormatter.mapToBadge(availableProvider: availableProvider, hasHighPriceImpactWarning: hasHighPriceImpactWarning)
        let badge: SendSwapProvidersSelectorProviderViewData.Badge? = switch providerBadge {
        case .none: .none
        case .fcaWarning: .fcaWarning
        case .permissionNeeded: .permissionNeeded
        case .bestRate: .bestRate
        }

        if let percentSubtitle = makePercentSubtitle(selectedProvider: selectedProvider, provider: availableProvider) {
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

    func userDidTap(providerId: String) {
        guard let provider = input?.expressProviders.first(where: { $0.provider.id == providerId }) else {
            return
        }

        analyticsLogger.logSendSwapProvidersChosen(provider: provider.provider)
        output?.userDidSelect(provider: provider)

        Task { @MainActor in dismiss() }
    }

    func makePercentSubtitle(selectedProvider: ExpressAvailableProvider?, provider: ExpressAvailableProvider) -> ProviderRowViewModel.Subtitle? {
        // For selectedProvider we don't add percent badge
        guard selectedProvider?.provider.id != provider.provider.id else {
            return nil
        }

        guard let quote = provider.getState().quote,
              let selectedRate = selectedProvider?.getState().quote?.rate else {
            return nil
        }

        let changePercent = quote.rate / selectedRate - 1
        let result = priceChangeFormatter.formatFractionalValue(changePercent, option: .express)
        return .percent(result.formattedText, signType: result.signType)
    }

    private func mapToFCAWarningIfNeeded(providers: [ExpressAvailableProvider]) -> NotificationViewInput? {
        let allProviderIds = providers.map { $0.provider.id }

        // Display FCA notification if the providers list contains FCA restriction for any provider
        let isRestrictableFCAIncluded = allProviderIds.contains(where: {
            ExpressConstants.expressProvidersFCAWarningList.contains($0)
        })

        if geoEligibilityService.isUK, isRestrictableFCAIncluded {
            return NotificationsFactory().buildNotificationInput(for: ExpressProvidersListEvent.fcaWarningList)
        } else {
            return nil
        }
    }
}
