//
//  PolymarketFastTradingActivationViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemLocalization
import TangemPolymarket
import TangemUI
import TangemUIUtils

@MainActor
final class PolymarketFastTradingActivationViewModel: ObservableObject, Identifiable {
    @Published private(set) var authorization: PolymarketFastTradingAuthorization?
    @Published private(set) var pendingChangeNotice: String?
    @Published private(set) var isProcessing = false
    @Published var isFAQPresented = false
    @Published var alert: AlertBinder?

    let signingButtonType: SigningActionButtonViewType

    private let service: PolymarketFastTradingServicing
    private let showProgress: @MainActor (String) -> Void
    private let onClose: () -> Void

    private var stateSubscription: AnyCancellable?

    init(
        service: PolymarketFastTradingServicing,
        signingButtonType: SigningActionButtonViewType,
        showProgress: @escaping @MainActor (String) -> Void = PolymarketFastTradingToast.showInfo,
        onClose: @escaping () -> Void
    ) {
        self.service = service
        self.signingButtonType = signingButtonType
        self.showProgress = showProgress
        self.onClose = onClose

        authorization = Self.authorization(for: service.state)
        pendingChangeNotice = Self.pendingChangeNotice(for: service.state)

        stateSubscription = service.statePublisher
            .receiveOnMain()
            .sink { [weak self] state in
                self?.apply(state)
            }
    }

    var buttonTitle: String {
        authorization?.title ?? Localization.commonActivate
    }

    var isButtonDisabled: Bool {
        authorization == nil
    }
}

// MARK: - View actions

extension PolymarketFastTradingActivationViewModel {
    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .onAppear:
            Task { await service.refresh() }
        case .authorize:
            authorize()
        case .openFAQ:
            isFAQPresented = true
        case .close:
            onClose()
        }
    }

    enum ViewAction {
        case onAppear
        case authorize
        case openFAQ
        case close
    }
}

// MARK: - Private implementation

private extension PolymarketFastTradingActivationViewModel {
    static func authorization(for state: PolymarketFastTradingState) -> PolymarketFastTradingAuthorization? {
        guard case .loaded(let assessment) = state else { return nil }

        return PolymarketFastTradingAuthorization(assessment: assessment)
    }

    static func pendingChangeNotice(for state: PolymarketFastTradingState) -> String? {
        guard case .loaded(let assessment) = state else { return nil }

        return PolymarketFastTradingAuthorization.pendingChangeNotice(for: assessment)
    }

    func apply(_ state: PolymarketFastTradingState) {
        guard !isProcessing else { return }

        let authorization = Self.authorization(for: state)
        let pendingChangeNotice = Self.pendingChangeNotice(for: state)

        if self.authorization != authorization {
            self.authorization = authorization
        }

        if self.pendingChangeNotice != pendingChangeNotice {
            self.pendingChangeNotice = pendingChangeNotice
        }
    }

    func authorize() {
        guard let authorization, !isProcessing else { return }

        isProcessing = true

        Task { [weak self, service, showProgress] in
            do {
                try await service.perform(authorization)
                self?.isProcessing = false
                showProgress(authorization.progressMessage)
                self?.onClose()
            } catch {
                self?.isProcessing = false

                guard let failure = PolymarketFastTradingFailure(error: error) else {
                    PolymarketLogger.info("Fast trading authorization was cancelled")
                    return
                }

                PolymarketLogger.error("Fast trading authorization failed", error: error)
                self?.alert = failure.alert
            }
        }
    }
}

// MARK: - Authorization

private extension PolymarketFastTradingServicing {
    func perform(_ authorization: PolymarketFastTradingAuthorization) async throws {
        switch authorization {
        case .enable, .reenable:
            try await enable()
        case .renew, .repair:
            try await renew()
        case .replace(let previous, let revokesPrevious):
            try await replace(previous: previous, revokesPrevious: revokesPrevious)
        }
    }
}
