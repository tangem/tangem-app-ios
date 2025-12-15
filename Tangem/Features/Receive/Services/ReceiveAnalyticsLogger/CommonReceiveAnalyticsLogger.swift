//
//  CommonReceiveAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

class CommonReceiveAnalyticsLogger {
    // MARK: - Private Properties

    private let flow: ReceiveFlow
    private let tokenItem: TokenItem

    // MARK: - Init

    init(flow: ReceiveFlow, tokenItem: TokenItem) {
        self.flow = flow
        self.tokenItem = tokenItem
    }
}

// MARK: - SelectorReceiveAssetsAnalyticsLogger

extension CommonReceiveAnalyticsLogger: SelectorReceiveAssetsAnalyticsLogger {
    func logSelectorReceiveAssetsScreenOpened(_ hasDomainNameAddresses: Bool) {
        let ensParameterValue = hasDomainNameAddresses ? Analytics.ParameterValue.full.rawValue : Analytics.ParameterValue.empty.rawValue

        Analytics.log(event: .receiveScreenOpened, params: [
            .token: tokenItem.currencySymbol,
            .blockchain: tokenItem.blockchain.displayName,
            .ens: ensParameterValue,
        ])
    }
}

// MARK: - QRCodeReceiveAssetsAnalyticsLogger

extension CommonReceiveAnalyticsLogger: QRCodeReceiveAssetsAnalyticsLogger {
    func logQRCodeReceiveAssetsScreenOpened() {
        Analytics.log(event: .qrScreenOpened, params: [
            .token: tokenItem.currencySymbol,
            .blockchain: tokenItem.blockchain.displayName,
        ])
    }

    func logCopyButtonTapped() {
        switch flow {
        case .nft:
            Analytics.log(
                event: .nftReceiveCopyAddressButtonClicked,
                params: [
                    .blockchain: tokenItem.blockchain.displayName,
                ]
            )
        case .crypto:
            Analytics.log(event: .buttonCopyAddress, params: [
                .token: tokenItem.currencySymbol,
                .blockchain: tokenItem.blockchain.displayName,
                .source: Analytics.ParameterValue.qr.rawValue,
            ])
        }
    }

    func logShareButtonTapped() {
        switch flow {
        case .nft:
            Analytics.log(event: .nftReceiveShareAddressButtonClicked, params: [
                .blockchain: tokenItem.blockchain.displayName,
            ])
        case .crypto:
            Analytics.log(event: .buttonShareAddress, params: [
                .token: tokenItem.currencySymbol,
                .blockchain: tokenItem.blockchain.displayName,
            ])
        }
    }
}

// MARK: - ItemSelectorReceiveAssetsAnalyticsLogger

extension CommonReceiveAnalyticsLogger: ItemSelectorReceiveAssetsAnalyticsLogger {
    func logCopyAddressButtonTapped() {
        Analytics.log(event: .buttonCopyAddress, params: [
            .token: tokenItem.currencySymbol,
            .blockchain: tokenItem.blockchain.displayName,
            .source: Analytics.ParameterValue.receive.rawValue,
        ])
    }

    func logShareDomainNameAddressButtonTapped() {
        Analytics.log(event: .buttonShareAddress, params: [
            .token: tokenItem.currencySymbol,
            .blockchain: tokenItem.blockchain.displayName,
            .source: Analytics.ParameterValue.receive.rawValue,
        ])
    }

    func logCopyDomainNameAddressButtonTapped() {
        Analytics.log(event: .buttonENS, params: [
            .token: tokenItem.currencySymbol,
            .blockchain: tokenItem.blockchain.displayName,
        ])
    }
}

// MARK: - ReceiveAnalyticsLogger

extension CommonReceiveAnalyticsLogger: ReceiveAnalyticsLogger {}
