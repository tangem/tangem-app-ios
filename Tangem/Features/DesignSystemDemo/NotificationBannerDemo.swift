//
//  NotificationBannerDemo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

final class NotificationBannerDemoViewModel: ObservableObject, Identifiable {}

struct NotificationBannerDemoView: View {
    @ObservedObject var viewModel: NotificationBannerDemoViewModel

    @State private var source: Source = .mapped
    @State private var stackingType: NotificaitonBannerContainerStackingType = .stack

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $source) {
                Text("Mapped (real)").tag(Source.mapped)
                Text("Showcase").tag(Source.showcase)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding([.horizontal, .top])

            Picker("", selection: $stackingType) {
                Text("Stack").tag(NotificaitonBannerContainerStackingType.stack)
                Text("Carousel").tag(NotificaitonBannerContainerStackingType.carousel)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            switch source {
            case .mapped:
                ScrollView {
                    NotificationBannerContainer(items: mappedBanners, stackingType: stackingType)
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                }
            case .showcase:
                NotificationBannerShowcase(stackingType: stackingType)
            }
        }
        .navigationBarTitle(Text("NotificationBanner"))
    }

    /// Real notification events rendered through `MultiWalletNotificationBannerMapper` — the exact
    /// pipeline the redesigned main screen uses, so demo output matches production banners.
    private var mappedBanners: [NotificationBannerItem] {
        let factory = NotificationsFactory()
        let inputs = Self.mainScreenEvents.map { factory.buildNotificationInput(for: $0) }
        return MultiWalletNotificationBannerMapper().mapItems([inputs])
    }

    private static var mainScreenEvents: [any NotificationEvent] {
        let general: [GeneralNotificationEvent] = [
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
            .missingDerivation(numberOfNetworks: 2, icon: nil, hasNFCInteraction: false),
            .walletLocked,
            .missingBackup,
            .supportedOnlySingleCurrencyWallet,
            .backupErrors,
            .mobileFinishActivation(hasPositiveBalance: true, hasBackup: false),
            .mobileUpgrade,
            .addFunds,
            .pushNotificationsPermissionRequest,
            .initialWalletTokenSyncCompleted,
        ]

        let multiWallet: [MultiWalletNotificationEvent] = [
            .someTokenBalancesNotUpdated,
            .someNetworksUnreachable(currencySymbols: ["BTC", "ETH"]),
        ]

        return general + multiWallet
    }
}

private extension NotificationBannerDemoView {
    enum Source: Hashable {
        case mapped
        case showcase
    }
}
