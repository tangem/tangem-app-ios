//
//  TangemPayPlasticReissueSheetViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemFoundation
import TangemLocalization

protocol TangemPayPlasticReissueSheetRoutable: AnyObject {
    func closePlasticReissueSheet()
}

final class TangemPayPlasticReissueSheetViewModel: ObservableObject, FloatingSheetContentViewModel, TangemPayPopupViewModel {
    var icon: Image {
        DesignSystem.Icons.ArrowRefresh.regular32.image
    }

    var title: AttributedString {
        .init(Localization.tangempayReissuePlasticTitle)
    }

    var description: AttributedString {
        .init(Localization.tangempayReissuePlasticDescription)
    }

    var primaryButton: MainButton.Settings {
        MainButton.Settings(
            title: Localization.tangempayCardDetailsReissueCard,
            style: .primary,
            size: .default,
            isDisabled: isInsufficientFunds,
            action: confirm
        )
    }

    var secondaryButton: MainButton.Settings? {
        MainButton.Settings(
            title: Localization.commonCancel,
            style: .secondary,
            size: .default,
            action: dismiss
        )
    }

    var infoRows: [TangemPayOrderCardInfoRow] {
        [
            TangemPayOrderCardInfoRow(
                id: .deliverTo,
                title: Localization.tangempayOrderTypeDeliveryTo,
                value: countryName ?? Constants.unknownValue
            ),
            TangemPayOrderCardInfoRow(
                id: .deliveryFee,
                title: Localization.tangempayOrderTypeDeliveryFee,
                value: feeText,
                badge: isInsufficientFunds
                    ? .init(text: Localization.tangempayOrderTypeNotEnoughMoney, appearance: .warning)
                    : nil
            ),
            TangemPayOrderCardInfoRow(
                id: .deliveryTime,
                title: Localization.tangempayOrderTypeDeliveryTime,
                value: Localization.tangempayOrderTypeDeliveryEta(deliveryEtaMaxDays)
            ),
        ]
    }

    private let userWalletId: UserWalletId
    private let countryName: String?
    private let feeText: String
    private let deliveryEtaMaxDays: Int
    private let isInsufficientFunds: Bool
    private weak var coordinator: TangemPayPlasticReissueSheetRoutable?
    private let confirmAction: () -> Void

    init(
        userWalletId: UserWalletId,
        countryName: String?,
        feeText: String,
        deliveryEtaMaxDays: Int,
        isInsufficientFunds: Bool,
        coordinator: TangemPayPlasticReissueSheetRoutable?,
        confirmAction: @escaping () -> Void
    ) {
        self.userWalletId = userWalletId
        self.countryName = countryName
        self.feeText = feeText
        self.deliveryEtaMaxDays = deliveryEtaMaxDays
        self.isInsufficientFunds = isInsufficientFunds
        self.coordinator = coordinator
        self.confirmAction = confirmAction

        Analytics.log(.visaReplaceCardConfirmationPopupOpened, contextParams: .userWallet(userWalletId))
    }

    func dismiss() {
        coordinator?.closePlasticReissueSheet()
    }
}

// MARK: - Private

private extension TangemPayPlasticReissueSheetViewModel {
    enum Constants {
        static let unknownValue = "—"
    }

    func confirm() {
        Analytics.log(.visaReplaceCardConfirmed, contextParams: .userWallet(userWalletId))
        confirmAction()
    }
}
