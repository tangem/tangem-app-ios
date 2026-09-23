//
//  PolymarketReceiveSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import SwiftUI
import TangemAssets
import TangemFoundation
import TangemLocalization
import TangemUI
import UIKit

final class PolymarketReceiveSheetViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Injected(\.overlayShareActivitiesPresenter) private var shareActivitiesPresenter: any ShareActivitiesPresenter

    @Published private(set) var viewState: ViewState = .info

    var isBackButtonVisible: Bool {
        switch viewState {
        case .info: false
        case .qrCode: true
        }
    }

    let tokenIcons: [TokenIconViewData]
    let heading: String
    let warningTitle: String
    let address: String
    let warningDescription: String
    let limitsDescription: String

    private let input: Input
    private let analyticsLogger: CommonReceiveAnalyticsLogger

    private weak var coordinator: PolymarketReceiveSheetRoutable?

    init(input: Input, coordinator: PolymarketReceiveSheetRoutable) {
        self.input = input
        self.coordinator = coordinator

        address = input.depositAddress

        analyticsLogger = CommonReceiveAnalyticsLogger(
            flow: .polymarketDeposit(minimumDepositFormatted: input.minimumDepositFormatted),
            tokenItem: input.primaryToken
        )

        let symbols = input.tokens.map(\.currencySymbol).joined(separator: " \(Localization.commonOr) ")
        heading = Localization.receiveBottomSheetWarningMessageCompact(symbols, input.networkTitle)
        warningTitle = Localization.receiveBottomSheetWarningTitle(symbols, input.networkTitle)

        warningDescription = Localization.receiveBottomSheetWarningMessageDescription
        limitsDescription = Localization.predictionAddFundsNotificationLimitsDescription(input.minimumDepositFormatted)

        let networkIcon = NetworkImageProvider().provide(by: input.blockchain, filled: true)
        tokenIcons = input.tokens.map { tokenItem in
            TokenIconViewData(
                id: tokenItem.contractAddress ?? tokenItem.currencySymbol,
                symbol: tokenItem.currencySymbol,
                url: IconURLBuilder().tokenIconURL(optionalId: tokenItem.id, size: .large),
                networkIcon: networkIcon
            )
        }

        analyticsLogger.logSelectorReceiveAssetsScreenOpened(false)
    }

    func showQRCode() {
        viewState = .qrCode(viewModel: makeQRCodeViewModel())
    }

    func onBackTap() {
        viewState = .info
    }

    func copy() {
        analyticsLogger.logCopyAddressButtonTapped()
        copyToClipboard(with: address)
    }

    func share() {
        share(with: address)
    }

    func close() {
        coordinator?.closeReceiveSheet()
    }
}

// MARK: - QRCodeReceiveAssetsRoutable

extension PolymarketReceiveSheetViewModel: QRCodeReceiveAssetsRoutable {
    func copyToClipboard(with address: String) {
        UIPasteboard.general.string = address

        Toast(
            view: TangemSnackbar(title: Localization.walletNotificationAddressCopied)
                .icon(DesignSystem.Icons.Checkmark.regular20)
                .iconColor(Color.Tangem.Graphic.Status.accent)
        )
        .present(layout: .top(padding: 12), type: .temporary())
    }

    func share(with address: String) {
        runTask(in: self) { @MainActor viewModel in
            viewModel.shareActivitiesPresenter.share(activityItems: [address])
        }
    }
}

// MARK: - Private implementation

private extension PolymarketReceiveSheetViewModel {
    func makeQRCodeViewModel() -> QRCodeReceiveAssetsViewModel {
        let colorScheme = ReceiveAddressInfoUtils.ColorScheme.whiteBlack

        return QRCodeReceiveAssetsViewModel(
            flow: .polymarketDeposit(minimumDepositFormatted: input.minimumDepositFormatted),
            tokenItem: input.primaryToken,
            addressInfo: ReceiveAddressInfo(
                address: address,
                type: .default,
                localizedName: "",
                qrBackgroundColor: colorScheme.backgroundColor,
                qrForegroundColor: colorScheme.foregroundColor
            ),
            headerOverride: heading,
            analyticsLogger: analyticsLogger,
            coordinator: self
        )
    }
}

// MARK: - Nested types

extension PolymarketReceiveSheetViewModel {
    enum ViewState {
        case info
        case qrCode(viewModel: QRCodeReceiveAssetsViewModel)
    }

    struct TokenIconViewData: Identifiable, Equatable {
        let id: String
        let symbol: String
        let url: URL?
        let networkIcon: ImageType
    }

    struct Input: Equatable {
        let depositAddress: String
        let minimumDepositFormatted: String
        let primaryToken: TokenItem
        let otherTokens: [TokenItem]

        var tokens: [TokenItem] { [primaryToken] + otherTokens }
        var blockchain: Blockchain { primaryToken.blockchain }
        var networkTitle: String { blockchain.displayName }

        init?(depositAddress: String, minimumDepositFormatted: String, tokens: [TokenItem]) {
            guard
                let primaryToken = tokens.first,
                tokens.allSatisfy({ $0.blockchainNetwork == primaryToken.blockchainNetwork })
            else {
                return nil
            }

            self.depositAddress = depositAddress
            self.minimumDepositFormatted = minimumDepositFormatted
            self.primaryToken = primaryToken
            otherTokens = Array(tokens.dropFirst())
        }
    }
}
