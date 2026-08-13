//
//  TangemPayReceiveSheetViewModel.swift
//  TangemApp
//
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

final class TangemPayReceiveSheetViewModel: ObservableObject, FloatingSheetContentViewModel {
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

    private let input: Input

    private weak var coordinator: TangemPayReceiveSheetRoutable?

    init(input: Input, coordinator: TangemPayReceiveSheetRoutable) {
        self.input = input
        self.coordinator = coordinator

        address = input.depositAddress

        let symbols = input.tokens.map(\.symbol).joined(separator: " \(Localization.commonOr) ")
        heading = Localization.receiveBottomSheetWarningMessageCompact(symbols, input.networkTitle)
        warningTitle = Localization.receiveBottomSheetWarningTitle(symbols, input.networkTitle)

        let networkIcon = NetworkImageProvider().provide(by: input.blockchain, filled: true)
        tokenIcons = input.tokens.map { token in
            TokenIconViewData(
                id: token.contractAddress,
                symbol: token.symbol,
                url: IconURLBuilder().tokenIconURL(optionalId: Self.coinId(for: token.symbol), size: .large),
                networkIcon: networkIcon
            )
        }
    }

    func showQRCode() {
        viewState = .qrCode(viewModel: makeQRCodeViewModel())
    }

    func onBackTap() {
        viewState = .info
    }

    func copy() {
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

extension TangemPayReceiveSheetViewModel: QRCodeReceiveAssetsRoutable {
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

// MARK: - Private

private extension TangemPayReceiveSheetViewModel {
    func makeQRCodeViewModel() -> QRCodeReceiveAssetsViewModel {
        let colorScheme = ReceiveAddressInfoUtils.ColorScheme.whiteBlack
        let tokenItem = primaryTokenItem

        return QRCodeReceiveAssetsViewModel(
            flow: .crypto,
            tokenItem: tokenItem,
            addressInfo: ReceiveAddressInfo(
                address: address,
                type: .default,
                localizedName: "",
                qrBackgroundColor: colorScheme.backgroundColor,
                qrForegroundColor: colorScheme.foregroundColor
            ),
            headerOverride: heading,
            analyticsLogger: CommonReceiveAnalyticsLogger(flow: .crypto, tokenItem: tokenItem),
            coordinator: self
        )
    }

    var primaryTokenItem: TokenItem {
        let token = input.tokens.first { Self.coinId(for: $0.symbol) != nil } ?? input.tokens.first

        return TokenItem.token(
            Token(
                name: token?.symbol ?? "",
                symbol: token?.symbol ?? "",
                contractAddress: token?.contractAddress ?? "",
                decimalCount: Constants.stablecoinDecimalCount,
                id: token.flatMap { Self.coinId(for: $0.symbol) },
                metadata: .fungibleTokenMetadata
            ),
            BlockchainNetwork(input.blockchain, derivationPath: nil)
        )
    }

    static func coinId(for symbol: String) -> String? {
        switch symbol.uppercased() {
        case "USDC": "usd-coin"
        case "USDT": "tether"
        default: nil
        }
    }

    enum Constants {
        static let stablecoinDecimalCount = 6
    }
}

// MARK: - Nested types

extension TangemPayReceiveSheetViewModel {
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
        let blockchain: Blockchain
        let networkTitle: String
        let depositAddress: String
        let tokens: [Token]

        struct Token: Equatable {
            let symbol: String
            let contractAddress: String
        }
    }
}
