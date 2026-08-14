//
//  NotificationBannerDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct NotificationBannerCatalogView: View {
    @State private var stackingType: NotificaitonBannerContainerStackingType = .stack

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $stackingType) {
                Text("Stack").tag(NotificaitonBannerContainerStackingType.stack)
                Text("Carousel").tag(NotificaitonBannerContainerStackingType.carousel)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            ScrollView {
                NotificationBannerContainer(items: mappedBanners, stackingType: stackingType)
                    .padding(.horizontal)
                    .padding(.bottom, 24)
            }
        }
        .background(DesignSystem.Color.bgSecondary.ignoresSafeArea())
    }

    /// Real notification events rendered through `MultiWalletNotificationBannerMapper` — the exact
    /// pipeline the redesigned main screen uses, so demo output matches production banners.
    private var mappedBanners: [NotificationBannerItem] {
        MultiWalletNotificationBannerMapper().mapItems([Self.mainScreenInputs])
    }
}

// MARK: - Inputs

private extension NotificationBannerCatalogView {
    static var mainScreenInputs: [NotificationViewInput] {
        let factory = NotificationsFactory()

        let general = factory.buildNotificationInputs(
            for: generalEvents,
            action: { _ in },
            buttonAction: { _, _ in },
            dismissAction: { _ in }
        )

        let others = otherEvents.map {
            factory.buildNotificationInput(for: $0, buttonAction: { _, _ in }, dismissAction: { _ in })
        }

        return general + others + handBuiltInputs
    }

    static var generalEvents: [GeneralNotificationEvent] {
        [
            .forceUpdateAvailable,
            .numberOfSignedHashesIncorrect,
            .rateApp,
            .failedToVerifyCard,
            .testnetCard,
            .demoCard,
            .oldDeviceOldCard,
            .oldCard,
            .devCard,
            .lowSignatures(count: 3),
            .legacyDerivation,
            .systemDeprecationTemporary,
            .systemDeprecationPermanent(version: "5.0", date: "01.01.2026"),
            .missingDerivation(numberOfNetworks: 2, icon: .trailing(Assets.tangemIcon), hasNFCInteraction: true),
            .missingBackup,
            .supportedOnlySingleCurrencyWallet,
            .backupErrors,
            .mobileFinishActivation(hasPositiveBalance: true, hasBackup: false),
            .mobileFinishActivation(hasPositiveBalance: false, hasBackup: false),
            .mobileFinishActivation(hasPositiveBalance: false, hasBackup: true),
            .mobileUpgrade,
            .addFunds,
            .initialWalletTokenSyncCompleted,
        ]
    }

    static var otherEvents: [any NotificationEvent] {
        multiWalletEvents + tokenEvents + tangemPayEvents
    }

    static var multiWalletEvents: [any NotificationEvent] {
        [
            MultiWalletNotificationEvent.someTokenBalancesNotUpdated,
            MultiWalletNotificationEvent.someNetworksUnreachable(currencySymbols: ["BTC", "ETH"]),
        ]
    }

    static var tokenEvents: [any NotificationEvent] {
        [
            TokenNotificationEvent.networkUnreachable(currencySymbol: "BTC"),
            TokenNotificationEvent.networkNotUpdated(lastUpdatedDate: Date()),
            TokenNotificationEvent.rentFee(rentMessage: "Your account will be charged 0.00007 SOL rent fee"),
            TokenNotificationEvent.noAccount(message: "To create an account, send 0.0001 XLM or more to your address"),
            TokenNotificationEvent.existentialDepositWarning(
                message: "Keep at least 0.0000333333 DOT on your account to avoid deletion"
            ),
            TokenNotificationEvent.manaLevel(currentMana: "80", maxMana: "100"),
            TokenNotificationEvent.maticMigration,
            TokenNotificationEvent.cloreMigration,
            TokenNotificationEvent.bnbBeaconChainRetirement,
            TokenNotificationEvent.dynamicAddressesFundsFound(currencySymbol: "BTC", blockchainName: "Bitcoin"),
            TokenNotificationEvent.staking(tokenIconInfo: demoTokenIconInfo, earnUpToFormatted: "7.5%", isBeta: false),
            TokenNotificationEvent.staking(tokenIconInfo: demoTokenIconInfo, earnUpToFormatted: "7.5%", isBeta: true),
            TokenNotificationEvent.notEnoughFeeForTransaction(configuration: notEnoughFeeConfiguration(purchaseAllowed: true)),
            TokenNotificationEvent.notEnoughFeeForTransaction(configuration: notEnoughFeeConfiguration(purchaseAllowed: false)),
            TokenNotificationEvent.hasUnfulfilledRequirements(
                configuration: .missingHederaTokenAssociation(
                    associationFee: .init(formattedValue: "0.05", currencySymbol: "HBAR")
                ),
                icon: .trailing(Assets.tangemIcon)
            ),
            TokenNotificationEvent.hasUnfulfilledRequirements(
                configuration: .missingHederaTokenAssociation(associationFee: nil),
                icon: nil
            ),
            TokenNotificationEvent.hasUnfulfilledRequirements(
                configuration: .incompleteKaspaTokenTransaction(
                    revealTransaction: .init(
                        formattedValue: "0.5",
                        currencySymbol: "KAS",
                        blockchainName: "Kaspa",
                        onTransactionDiscard: {}
                    )
                ),
                icon: .trailing(Assets.tangemIcon)
            ),
            TokenNotificationEvent.hasUnfulfilledRequirements(
                configuration: .missingTokenTrustline(
                    .init(
                        reserveCurrencySymbol: "XLM",
                        reserveAmount: "0.5",
                        icon: Tokens.stellarFill,
                        trustlineOperationInProgress: false,
                        canPerformAction: true
                    )
                ),
                icon: nil
            ),
            TokenNotificationEvent.hasUnfulfilledRequirements(
                configuration: .missingTokenTrustline(
                    .init(
                        reserveCurrencySymbol: "XRP",
                        reserveAmount: "0.2",
                        icon: Tokens.xrpFill,
                        trustlineOperationInProgress: true,
                        canPerformAction: true
                    )
                ),
                icon: nil
            ),
        ]
    }

    static var tangemPayEvents: [any NotificationEvent] {
        [
            TangemPayNotificationEvent.unavailable,
            TangemPayNotificationEvent.sessionExpired(icon: .trailing(Assets.tangemIcon), isRenewing: false),
            TangemPayNotificationEvent.tangemPayIsNowBeta,
        ]
    }

    static var handBuiltInputs: [NotificationViewInput] {
        [
            input(for: GeneralNotificationEvent.walletLocked(hasNFCInteraction: false), buttons: [.unlock(icon: nil)]),
            input(
                for: GeneralNotificationEvent.pushNotificationsPermissionRequest,
                buttons: [.postponePushPermissionRequest, .allowPushPermissionRequest]
            ),
            input(
                for: YieldAPYBoostBannerNotificationEvent(),
                buttons: [.yieldBoostPromoLater, .openYieldBoostPromo(buttonTitle: Localization.commonExplore)]
            ),
            input(
                for: GetTangemPayBannerNotificationEvent(),
                buttons: [.closeGetTangemPay, .openGetTangemPay]
            ),
        ]
    }

    static func input(
        for event: any NotificationEvent,
        buttons: [NotificationButtonActionType]
    ) -> NotificationViewInput {
        NotificationViewInput(
            style: .withButtons(
                buttons.map { NotificationView.NotificationButton(action: { _, _ in }, actionType: $0, isWithLoader: false) }
            ),
            severity: event.severity,
            settings: .init(event: event, dismissAction: { _ in })
        )
    }

    static var demoTokenIconInfo: TokenIconInfo {
        TokenIconInfo(name: "Solana", blockchainIconAsset: nil, imageURL: nil, isCustom: false, customTokenColor: nil)
    }

    static func notEnoughFeeConfiguration(purchaseAllowed: Bool) -> TokenNotificationEvent.NotEnoughFeeConfiguration {
        TokenNotificationEvent.NotEnoughFeeConfiguration(
            amountCurrencySymbol: "USDT",
            amountCurrencyBlockchainName: "Ethereum",
            transactionAmountTypeName: "Tether",
            feeAmountTypeName: "Ethereum",
            feeAmountTypeCurrencySymbol: "ETH",
            feeTokenIconInfo: TokenIconInfo(
                name: "Ethereum",
                blockchainIconAsset: nil,
                imageURL: nil,
                isCustom: false,
                customTokenColor: nil
            ),
            networkName: "Ethereum",
            currencyButtonTitle: purchaseAllowed ? nil : "POL",
            isFeeCurrencyPurchaseAllowed: purchaseAllowed
        )
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        NotificationBannerCatalogView()
    }
    .preferredColorScheme(.dark)
}

#Preview("Critical & warning") {
    let events: [GeneralNotificationEvent] = [
        .failedToVerifyCard,
        .backupErrors,
        .missingBackup,
        .numberOfSignedHashesIncorrect,
        .mobileFinishActivation(hasPositiveBalance: true, hasBackup: false),
        .mobileFinishActivation(hasPositiveBalance: false, hasBackup: false),
        .lowSignatures(count: 3),
    ]
    let inputs = NotificationsFactory().buildNotificationInputs(
        for: events,
        action: { _ in },
        buttonAction: { _, _ in },
        dismissAction: { _ in }
    )

    return ScrollView {
        NotificationBannerContainer(
            items: MultiWalletNotificationBannerMapper().mapItems([inputs]),
            stackingType: .stack
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}
