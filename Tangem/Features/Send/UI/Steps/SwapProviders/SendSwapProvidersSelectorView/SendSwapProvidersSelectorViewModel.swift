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
import TangemLocalization

class SendSwapProvidersSelectorViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter
    @Injected(\.geoEligibilityService) private var geoEligibilityService: GeoEligibilityService

    // MARK: - ViewState

    @Published var ukNotificationInput: NotificationViewInput?
    @Published var providerViewModels: [SendSwapProvidersSelectorProviderViewData] = []
    @Published var providerTypeFilterOptions: [ProviderTypeFilter] = []
    @Published var selectedProviderTypeFilter: ProviderTypeFilter = .all

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

        let showableProvidersPublisher = Publishers.CombineLatest3(
            input.selectedExpressProviderPublisher.map { $0?.value },
            input.expressProvidersPublisher,
            input.currentRateTypePublisher
        )
        .map { selectedProvider, providers, currentRateType -> ShowableProvidersState in
            let showable = providers.showableProviders(selectedProviderId: selectedProvider?.provider.id)
            return ShowableProvidersState(selectedProvider: selectedProvider, providers: showable)
        }

        showableProvidersPublisher
            .map { Self.computeFilterOptions(showableProviders: $0.providers) }
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, options in
                viewModel.providerTypeFilterOptions = options
                if options.isEmpty, viewModel.selectedProviderTypeFilter != .all {
                    viewModel.selectedProviderTypeFilter = .all
                }
            }
            .store(in: &bag)

        Publishers.CombineLatest3(
            showableProvidersPublisher,
            highPriceImpactPublisher,
            $selectedProviderTypeFilter
        )
        .withWeakCaptureOf(self)
        .map { viewModel, values in
            let (state, highPriceImpactValue, filter) = values
            let hasWarning = highPriceImpactValue.map { !$0.level.isNegligible } ?? false
            return viewModel.prepareProviderRows(
                selectedProvider: state.selectedProvider,
                showableProviders: state.providers,
                providerTypeFilter: filter,
                hasHighPriceImpactWarning: hasWarning
            )
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

    static func computeFilterOptions(showableProviders: [ExpressAvailableProvider]) -> [ProviderTypeFilter] {
        guard FeatureProvider.isAvailable(.swapProviderTypeFilter) else { return [] }
        var hasCex = false
        var hasDex = false
        for available in showableProviders {
            switch available.provider.type {
            case .cex: hasCex = true
            case .dex, .dexBridge: hasDex = true
            case .onramp, .unknown: break
            }
            if hasCex, hasDex { break }
        }
        guard hasCex, hasDex else { return [] }
        return [.all, .cex, .dex]
    }

    private func prepareProviderRows(selectedProvider: ExpressAvailableProvider?, showableProviders: [ExpressAvailableProvider], providerTypeFilter: ProviderTypeFilter, hasHighPriceImpactWarning: Bool) -> [SendSwapProvidersSelectorProviderViewData] {
        showableProviders
            .filter { providerTypeFilter.matches($0.provider.type) }
            .sortedByAttractively()
            .map { mapToSendSwapProvidersSelectorProviderViewData(selectedProvider: selectedProvider, availableProvider: $0, hasHighPriceImpactWarning: hasHighPriceImpactWarning) }
    }

    func mapToSendSwapProvidersSelectorProviderViewData(selectedProvider: ExpressAvailableProvider?, availableProvider: ExpressAvailableProvider, hasHighPriceImpactWarning: Bool) -> SendSwapProvidersSelectorProviderViewData {
        let destinationTokenItem = receiveTokenInput?.receiveToken.value?.tokenItem
        var subtitles: [ProviderRowViewModel.Subtitle] = []

        let state = availableProvider.state
        subtitles.append(
            expressProviderFormatter.mapToRateSubtitle(
                state: state,
                senderTokenItem: tokenItem,
                destinationTokenItem: destinationTokenItem,
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

        guard let quote = provider.state.quote,
              let selectedRate = selectedProvider?.state.quote?.rate else {
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

// MARK: - ProviderTypeFilter

extension SendSwapProvidersSelectorViewModel {
    enum ProviderTypeFilter: Hashable, TangemSegmentedPickerTextProvider {
        case all
        case cex
        case dex

        var text: String {
            switch self {
            case .all: Localization.commonAll
            case .cex: ExpressProviderType.cex.title
            case .dex: ExpressProviderType.dex.title
            }
        }

        func matches(_ type: ExpressProviderType) -> Bool {
            switch self {
            case .all: true
            case .cex: type == .cex
            case .dex: type == .dex || type == .dexBridge
            }
        }
    }
}

// MARK: - ShowableProvidersState

private struct ShowableProvidersState {
    let selectedProvider: ExpressAvailableProvider?
    let providers: [ExpressAvailableProvider]
}
