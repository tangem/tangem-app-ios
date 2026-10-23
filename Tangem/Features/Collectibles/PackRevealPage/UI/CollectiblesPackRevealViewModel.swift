//
//  CollectiblesPackRevealViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import SwiftUI
import TangemAssets
import TangemFoundation
import TangemCollectibles
import TangemLocalization
import TangemUI

@MainActor
final class CollectiblesPackRevealViewModel: ObservableObject {
    // MARK: - Properties

    private let darkVideoURL: URL?
    private let lightVideoURL: URL?
    private let player: any CollectiblesRevealPlayer
    private let nftAddress: String?
    private let offerProvider: any CollectiblesBuybackOfferProvider
    private let buybackInteractor: any CollectiblesBuybackInteractor
    private let delayProvider: any PollDelayProvider
    private let refreshBalance: () async -> Void
    private let appStateObserver: AppStateObserver

    private weak var routable: (any CollectiblesPackRevealRoutable)?

    let prize: CollectiblesPackRevealView.Prize
    let signingActionButtonType: SigningActionButtonViewType

    var shouldCheckOffer: Bool {
        sellBackState.isAwaitingOffer && !isInBackground
    }

    // MARK: - Publishers

    @Published private(set) var videoPlayer: AVPlayer?
    @Published private(set) var sellBackState: SellBackState
    @Published private var isInBackground = false

    // MARK: - Init

    init(
        darkVideoURL: URL?,
        lightVideoURL: URL?,
        wonCard: CollectiblesWonCard,
        player: any CollectiblesRevealPlayer,
        offerProvider: any CollectiblesBuybackOfferProvider,
        buybackInteractor: any CollectiblesBuybackInteractor,
        signingActionButtonType: SigningActionButtonViewType,
        routable: (any CollectiblesPackRevealRoutable)?,
        delayProvider: any PollDelayProvider = TaskSleepPollDelayProvider(),
        notificationCenter: NotificationCenter = .default,
        refreshBalance: @escaping () async -> Void
    ) {
        self.darkVideoURL = darkVideoURL
        self.lightVideoURL = lightVideoURL
        self.player = player
        nftAddress = wonCard.nftAddress
        self.offerProvider = offerProvider
        self.buybackInteractor = buybackInteractor
        self.delayProvider = delayProvider
        self.refreshBalance = refreshBalance
        self.routable = routable
        prize = CollectiblesPackRevealView.Prize(wonCard: wonCard)
        self.signingActionButtonType = signingActionButtonType
        sellBackState = wonCard.nftAddress == nil ? .unavailable : .checking
        appStateObserver = AppStateObserver(notificationCenter: notificationCenter)

        self.player.videoPlayerPublisher.assign(to: &$videoPlayer)

        appStateObserver.start { [weak self] isInBackground in
            self?.isInBackground = isInBackground
        }
    }

    // MARK: - Methods

    func playVideo(for colorScheme: ColorScheme) async throws -> CollectiblesRevealPlayerResult {
        try await player.play(videoURL: colorScheme == .dark ? darkVideoURL : lightVideoURL)
    }

    func skip() {
        player.skip()
    }

    func checkOffer() async {
        guard let nftAddress, shouldCheckOffer else { return }

        let polling = PollingSequence(
            interval: Constants.offerCheckInterval,
            request: { [offerProvider] in try await offerProvider.load(nftAddress: nftAddress) },
            delayProvider: delayProvider
        )

        for await result in polling {
            switch result {
            case .success(let offer?):
                sellBackState = .available(offer)
                return
            case .success(nil):
                sellBackState = .unavailable
            case .failure(let error):
                CollectiblesLogger.error("Collectibles buyback offer check failed", error: error)
                sellBackState = .unavailable
            }
        }
    }

    func sellBack() {
        guard case .available(let offer) = sellBackState, let nftAddress else { return }

        sellBackState = .selling(offer)

        Task { [weak self, buybackInteractor, refreshBalance] in
            do {
                try await buybackInteractor.sell(nftAddress: nftAddress, offer: offer)
                self?.didSell(offer)
            } catch {
                self?.handleSaleFailure(error, offer: offer)
            }

            await refreshBalance()
        }
    }
}

// MARK: - Sell back state

extension CollectiblesPackRevealViewModel {
    enum SellBackState: Equatable {
        case checking
        case unavailable
        case available(CollectiblesBuybackOffer)
        case selling(CollectiblesBuybackOffer)

        var title: String {
            switch self {
            case .checking, .unavailable:
                Localization.collectiblesOpenPackBuybackUnavailable
            case .available(let offer), .selling(let offer):
                Localization.collectiblesOpenPackSellBackButton(
                    CollectiblesPriceFormatter.formatWithCents(offer.amount)
                )
            }
        }

        var isLoading: Bool {
            switch self {
            case .checking, .selling: true
            case .unavailable, .available: false
            }
        }

        var isSelling: Bool {
            guard case .selling = self else { return false }

            return true
        }

        var isAwaitingOffer: Bool {
            switch self {
            case .checking, .unavailable: true
            case .available, .selling: false
            }
        }
    }
}

// MARK: - Private logic

private extension CollectiblesPackRevealViewModel {
    func didSell(_ offer: CollectiblesBuybackOffer) {
        Self.presentToast(
            title: Localization.collectiblesOpenPackSellBackSuccess(
                CollectiblesPriceFormatter.formatWithCents(offer.amount)
            ),
            icon: DesignSystem.Icons.Success.filled20,
            iconColor: DesignSystem.Color.iconStatusSuccess
        )
        routable?.returnToMachine()
    }

    func handleSaleFailure(_ error: any Error, offer: CollectiblesBuybackOffer) {
        guard !(error is CancellationError) else {
            sellBackState = .available(offer)
            return
        }

        sellBackState = .checking

        Self.presentToast(
            title: Localization.commonSomethingWentWrong,
            icon: DesignSystem.Icons.Error.filled20,
            iconColor: DesignSystem.Color.iconStatusError
        )
    }

    static func presentToast(title: String, icon: ImageType, iconColor: Color) {
        Toast(view: TangemSnackbar(title: title).icon(icon).iconColor(iconColor))
            .present(layout: .top(padding: Constants.toastTopPadding), type: .temporary())
    }
}

// MARK: - Constants

private extension CollectiblesPackRevealViewModel {
    enum Constants {
        static let offerCheckInterval: TimeInterval = 5
        static let toastTopPadding: CGFloat = 14
    }
}
