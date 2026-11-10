//
//  PolymarketFastTradingViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemPolymarket
import TangemUI
import TangemUIUtils

@MainActor
final class PolymarketFastTradingViewModel: ObservableObject, Identifiable {
    @Published private var state: PolymarketFastTradingState
    @Published private(set) var isProcessing = false
    @Published var revocation: Revocation?
    @Published var activation: PolymarketFastTradingActivationViewModel?
    @Published var isFAQPresented = false
    @Published var alert: AlertBinder?

    let signingButtonType: SigningActionButtonViewType

    private let service: PolymarketFastTradingOperating
    private let thisDeviceName: String
    private let onClose: () -> Void

    private var stateSubscription: AnyCancellable?

    init(
        service: PolymarketFastTradingOperating,
        signingButtonType: SigningActionButtonViewType,
        thisDeviceName: String,
        onClose: @escaping () -> Void
    ) {
        self.service = service
        self.signingButtonType = signingButtonType
        self.thisDeviceName = thisDeviceName
        self.onClose = onClose

        state = service.state

        stateSubscription = service.statePublisher
            .receiveOnMain()
            .sink { [weak self] state in
                self?.state = state
            }
    }
}

// MARK: - Content

extension PolymarketFastTradingViewModel {
    var thisDevice: ThisDeviceSection {
        ThisDeviceSection(state: state, thisDeviceName: thisDeviceName)
    }

    var otherDevices: [PolymarketFastTradingDevice] {
        assessment.map { PolymarketFastTradingDevice.devices(from: $0, thisDeviceName: thisDeviceName) }?.filter { !$0.isThisDevice } ?? []
    }

    var foreignSigners: [ForeignSigner] {
        let foreign = (assessment?.foreignSigners ?? []).map { ForeignSigner($0, isBeingRevoked: false) }
        let beingRevoked = (assessment?.signersBeingRevoked ?? []).map { ForeignSigner($0, isBeingRevoked: true) }

        return foreign + beingRevoked
    }

    var hasUnknownForeignSigners: Bool {
        foreignSigners.contains { !$0.isBeingRevoked }
    }

    private var assessment: PolymarketFastTradingAssessment? {
        guard case .loaded(let assessment) = state else { return nil }

        return assessment
    }
}

// MARK: - View actions

extension PolymarketFastTradingViewModel {
    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .onAppear, .retry:
            Task { await service.refresh() }
        case .close:
            onClose()
        case .openFAQ:
            isFAQPresented = true
        case .openActivation:
            openActivation()
        case .device(let action, let device):
            perform(action, on: device)
        case .revokeForeignSigner(let signer):
            revocation = Revocation(address: signer.address, title: signer.title, kind: .foreignSigner)
        case .confirmRevocation:
            revoke()
        }
    }

    func refresh() async {
        await service.refresh()
    }

    enum ViewAction {
        case onAppear
        case retry
        case close
        case openFAQ
        case openActivation
        case device(PolymarketFastTradingDevice.Action, PolymarketFastTradingDevice)
        case revokeForeignSigner(ForeignSigner)
        case confirmRevocation
    }
}

// MARK: - Private implementation

private extension PolymarketFastTradingViewModel {
    func openActivation() {
        activation = PolymarketFastTradingActivationViewModel(
            service: service,
            signingButtonType: signingButtonType,
            onClose: { [weak self] in self?.activation = nil }
        )
    }

    func perform(_ action: PolymarketFastTradingDevice.Action, on device: PolymarketFastTradingDevice) {
        switch action {
        case .activate, .reactivate, .extend:
            openActivation()
        case .pause, .resume:
            guard case .sessionKey(let address) = device.source else { return }

            run(action) { [service] in
                try await service.setEnabled(action == .resume, sessionKeyAddress: address)
            }
        case .revoke:
            guard case .sessionKey(let address) = device.source else { return }

            revocation = Revocation(address: address, title: device.name, kind: .device)
        }
    }

    func revoke() {
        guard let revocation else { return }

        run(.revoke) { [service, weak self] in
            try await service.revoke(sessionKeyAddress: revocation.address)
            self?.revocation = nil
            PolymarketFastTradingToast.showInfoBelowNavigationBar(PolymarketFastTradingStrings.revocationInProgress)
        }
    }

    func run(_ action: PolymarketFastTradingDevice.Action, _ operation: @escaping @MainActor () async throws -> Void) {
        guard !isProcessing else { return }

        isProcessing = true

        Task { [weak self] in
            do {
                try await operation()
            } catch {
                if let failure = PolymarketFastTradingFailure(error: error) {
                    PolymarketLogger.error(error: "Fast trading \(action) failed: \(PolymarketFastTradingFailure.logDescription(of: error))")
                    self?.alert = failure.alert
                } else {
                    PolymarketLogger.info("Fast trading \(action) was cancelled")
                }
            }

            self?.isProcessing = false
        }
    }
}

// MARK: - Types

extension PolymarketFastTradingViewModel {
    enum ThisDeviceSection: Equatable {
        case device(PolymarketFastTradingDevice)
        case activationOffer(PolymarketFastTradingAuthorization)
        case notice(String)
        case loading
        case failed
        case exchangeUnreadable

        init(state: PolymarketFastTradingState, thisDeviceName: String) {
            switch state {
            case .loading:
                self = .loading
            case .failed:
                self = .failed
            case .loaded(let assessment):
                self.init(assessment: assessment, thisDeviceName: thisDeviceName)
            }
        }

        private init(assessment: PolymarketFastTradingAssessment, thisDeviceName: String) {
            if assessment.isExchangeUnreadable, !assessment.isOperationInFlight {
                self = .exchangeUnreadable
            } else if let device = PolymarketFastTradingDevice.devices(from: assessment, thisDeviceName: thisDeviceName).first(where: \.isThisDevice) {
                self = .device(device)
            } else if let authorization = PolymarketFastTradingAuthorization(assessment: assessment) {
                self = .activationOffer(authorization)
            } else if let notice = PolymarketFastTradingAuthorization.pendingChangeNotice(for: assessment) {
                self = .notice(notice)
            } else {
                self = .notice(PolymarketFastTradingStrings.changeInProgress)
            }
        }
    }

    struct Revocation: Identifiable, Equatable {
        let address: String
        let title: String
        let kind: Kind

        var id: String { address }

        var message: String {
            switch kind {
            case .device:
                PolymarketFastTradingStrings.revocationDescription(title)
            case .foreignSigner:
                PolymarketFastTradingStrings.foreignSignerRevocationDescription(title)
            }
        }

        enum Kind: Equatable {
            case device
            case foreignSigner
        }
    }

    struct ForeignSigner: Identifiable, Equatable {
        let address: String
        let title: String
        let isBeingRevoked: Bool

        var id: String { address }
    }
}

// MARK: - Foreign signer

private extension PolymarketFastTradingViewModel.ForeignSigner {
    init(_ signer: PolymarketSessionSigner, isBeingRevoked: Bool) {
        self.init(address: signer.address, title: AddressFormatter(address: signer.address).truncated(), isBeingRevoked: isBeingRevoked)
    }
}
