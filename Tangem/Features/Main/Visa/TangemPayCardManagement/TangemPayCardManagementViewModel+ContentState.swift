//
//  TangemPayCardManagementViewModel+ContentState.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPay

extension TangemPayCardManagementViewModel {
    enum ContentState {
        case renaming(TangemPayCardRenameViewModel)
        case closing
        case plastic(Plastic, email: String?)
        case issuing
        case reissuing
        case details(Details)

        enum Plastic {
            case delivering
            case awaitingActivation
            case activating

            init(_ plastic: TangemPayCardEntry.Plastic) {
                switch plastic {
                case .delivering: self = .delivering
                case .awaitingActivation(_, let isActivating): self = isActivating ? .activating : .awaitingActivation
                }
            }

            var messageStage: TangemPayCardEntry.Plastic.Stage {
                switch self {
                case .delivering, .awaitingActivation: .delivering
                case .activating: .activating
                }
            }
        }

        struct Details {
            let freezingState: TangemPayFreezingState
            let dailyLimitState: TangemPayDailyLimitState?
            let showsAddToApplePayGuide: Bool
        }

        enum Footer {
            case rename(TangemPayCardRenameViewModel)
            case plastic(isActivateAvailable: Bool)
        }
    }
}

extension TangemPayCardManagementViewModel.ContentState {
    var footer: Footer? {
        switch self {
        case .renaming(let renameViewModel): .rename(renameViewModel)
        case .plastic(.delivering, _): .plastic(isActivateAvailable: false)
        case .plastic(.awaitingActivation, _): .plastic(isActivateAvailable: true)
        case .plastic(.activating, _), .closing, .issuing, .reissuing, .details: nil
        }
    }

    var isReplaceCardAvailable: Bool {
        switch self {
        case .plastic: false
        case .renaming, .closing, .issuing, .reissuing, .details: true
        }
    }

    var isRenaming: Bool {
        switch self {
        case .renaming: true
        case .closing, .plastic, .issuing, .reissuing, .details: false
        }
    }

    var isPlasticInTransit: Bool {
        switch self {
        case .plastic(.delivering, _), .plastic(.awaitingActivation, _): true
        case .plastic(.activating, _), .renaming, .closing, .issuing, .reissuing, .details: false
        }
    }

    var freezingState: TangemPayFreezingState? {
        switch self {
        case .details(let details): details.freezingState
        case .renaming, .closing, .plastic, .issuing, .reissuing: nil
        }
    }

    var isClosing: Bool {
        switch self {
        case .closing: true
        case .renaming, .plastic, .issuing, .reissuing, .details: false
        }
    }
}

// MARK: - CardLifecycle

extension TangemPayCardManagementViewModel {
    struct CardLifecycle {
        let freezingState: TangemPayFreezingState
        let dailyLimitState: TangemPayDailyLimitState?
        let isReissuing: Bool
        let isClosing: Bool

        init(
            status: VisaCustomerInfoResponse.ProductStatus,
            operation: TangemPayCard.LifecycleOperation?,
            dailyLimitState: TangemPayDailyLimitState?
        ) {
            freezingState = TangemPayFreezingState(status: status, operation: operation)
            self.dailyLimitState = dailyLimitState
            isReissuing = operation == .reissue
            isClosing = operation == .close
        }
    }
}

// MARK: - TangemPayFreezingState

extension TangemPayFreezingState {
    init(status: VisaCustomerInfoResponse.ProductStatus, operation: TangemPayCard.LifecycleOperation?) {
        self = switch operation {
        case .freeze: .freezingInProgress
        case .unfreeze: .unfreezingInProgress
        case .reissue, .close, nil: status == .blocked ? .frozen : .normal
        }
    }
}
