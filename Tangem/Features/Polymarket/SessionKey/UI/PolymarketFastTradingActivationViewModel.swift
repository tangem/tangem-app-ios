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
    @Published private(set) var buttonTitle: String
    @Published private(set) var pendingChangeNotice: String?
    @Published private(set) var isProcessing = false
    @Published var isFAQPresented = false

    let signingButtonType: SigningActionButtonViewType

    private let service: PolymarketFastTradingOperating
    private let showProgress: @MainActor (String) -> Void
    private let showFailure: @MainActor (PolymarketFastTradingFailure) -> Void
    private let onClose: () -> Void

    private var stateSubscription: AnyCancellable?

    init(
        service: PolymarketFastTradingOperating,
        signingButtonType: SigningActionButtonViewType,
        showProgress: @escaping @MainActor (String) -> Void = PolymarketFastTradingToast.showInfo,
        showFailure: @escaping @MainActor (PolymarketFastTradingFailure) -> Void = PolymarketFastTradingToast.showFailure,
        onClose: @escaping () -> Void
    ) {
        self.service = service
        self.signingButtonType = signingButtonType
        self.showProgress = showProgress
        self.showFailure = showFailure
        self.onClose = onClose

        authorization = Self.authorization(for: service.state)
        buttonTitle = Self.buttonTitle(for: service.state)
        pendingChangeNotice = Self.pendingChangeNotice(for: service.state)

        stateSubscription = service.statePublisher
            .sink { [weak self] state in
                self?.apply(state)
            }
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

    static func buttonTitle(for state: PolymarketFastTradingState) -> String {
        guard
            case .loaded(let assessment) = state,
            let authorization = PolymarketFastTradingAuthorization(assessment: assessment),
            !assessment.isLocalActivationFailed
        else {
            return Localization.commonActivate
        }

        return authorization.title
    }

    static func pendingChangeNotice(for state: PolymarketFastTradingState) -> String? {
        guard case .loaded(let assessment) = state else { return nil }

        return PolymarketFastTradingAuthorization.pendingChangeNotice(for: assessment)
    }

    func apply(_ state: PolymarketFastTradingState) {
        guard !isProcessing else { return }

        let authorization = Self.authorization(for: state)
        let buttonTitle = Self.buttonTitle(for: state)
        let pendingChangeNotice = Self.pendingChangeNotice(for: state)

        if self.authorization != authorization {
            self.authorization = authorization
        }

        if self.buttonTitle != buttonTitle {
            self.buttonTitle = buttonTitle
        }

        if self.pendingChangeNotice != pendingChangeNotice {
            self.pendingChangeNotice = pendingChangeNotice
        }
    }

    func authorize() {
        guard let authorization, !isProcessing else { return }

        isProcessing = true

        Task { [weak self, service, showProgress, showFailure] in
            defer { self?.isProcessing = false }

            do {
                try await service.authorize(authorization)
                showProgress(authorization.progressMessage)
                self?.onClose()
            } catch {
                guard let failure = PolymarketFastTradingFailure(error: error, authorizing: authorization.operation) else {
                    PolymarketLogger.info("Fast trading authorization was cancelled")
                    return
                }

                PolymarketLogger.error(error: "Fast trading authorization failed: \(PolymarketFastTradingFailure.logDescription(of: error))")
                showFailure(PolymarketFastTradingFailure(error: error) == .busy ? .busy : failure)
            }
        }
    }
}
