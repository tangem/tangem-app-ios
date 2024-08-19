//
//  SendCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import BlockchainSdk

class SendCoordinator: CoordinatorObject {
    let dismissAction: Action<(walletModel: WalletModel, userWalletModel: UserWalletModel)?>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Dependencies

    @Injected(\.safariManager) private var safariManager: SafariManager

    // MARK: - Root view model

    @Published private(set) var rootViewModel: SendViewModel?

    // MARK: - Child coordinators

    // MARK: - Child view models

    @Published var mailViewModel: MailViewModel? = nil
    @Published var qrScanViewCoordinator: QRScanViewCoordinator? = nil
    @Published var expressApproveViewModel: ExpressApproveViewModel?

    required init(
        dismissAction: @escaping Action<(walletModel: WalletModel, userWalletModel: UserWalletModel)?>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        let factory = SendFlowFactory(userWalletModel: options.userWalletModel, walletModel: options.walletModel)

        switch options.type {
        case .send:
            rootViewModel = factory.makeSendViewModel(router: self)
        case .sell(let parameters):
            rootViewModel = factory.makeSellViewModel(sellParameters: parameters, router: self)
        case .staking(let manager):
            rootViewModel = factory.makeStakingViewModel(manager: manager, router: self)
        case .unstaking(let manager, let balanceInfo):
            rootViewModel = factory.makeUnstakingViewModel(manager: manager, balanceInfo: balanceInfo, router: self)
        }
    }
}

// MARK: - Options

extension SendCoordinator {
    struct Options {
        let walletModel: WalletModel
        let userWalletModel: UserWalletModel
        let type: SendType
    }
}

// MARK: - SendRoutable

extension SendCoordinator: SendRoutable {
    func dismiss() {
        dismiss(with: nil)
    }

    func openMail(with dataCollector: EmailDataCollector, recipient: String) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: .failedToSendTx)
    }

    func openFeeExplanation(url: URL) {
        safariManager.openURL(url)
    }

    func openExplorer(url: URL) {
        safariManager.openURL(url)
    }

    func openShareSheet(url: URL) {
        AppPresenter.shared.show(UIActivityViewController(activityItems: [url], applicationActivities: nil))
    }

    func openQRScanner(with codeBinding: Binding<String>, networkName: String) {
        Analytics.log(.sendButtonQRCode)

        let qrScanViewCoordinator = QRScanViewCoordinator { [weak self] in
            self?.qrScanViewCoordinator = nil
        }

        let text = Localization.sendQrcodeScanInfo(networkName)
        let options = QRScanViewCoordinator.Options(code: codeBinding, text: text)
        qrScanViewCoordinator.start(with: options)

        self.qrScanViewCoordinator = qrScanViewCoordinator
    }

    func openFeeCurrency(for walletModel: WalletModel, userWalletModel: UserWalletModel) {
        dismiss(with: (walletModel, userWalletModel))
    }

    func openApproveView(settings: ExpressApproveViewModel.Settings, approveViewModelInput: any ApproveViewModelInput) {
        expressApproveViewModel = .init(
            settings: settings,
            feeFormatter: CommonFeeFormatter(
                balanceFormatter: .init(),
                balanceConverter: .init()
            ),
            logger: AppLog.shared,
            approveViewModelInput: approveViewModelInput,
            coordinator: self
        )
    }
}

// MARK: - ExpressApproveRoutable

extension SendCoordinator: ExpressApproveRoutable {
    func didSendApproveTransaction() {
        expressApproveViewModel = nil
    }

    func userDidCancel() {
        expressApproveViewModel = nil
    }
}
