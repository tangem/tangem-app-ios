//
//  UnlockUserWalletBottomSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import TangemUIUtils
import TangemLocalization
import TangemFoundation

protocol UnlockUserWalletBottomSheetDelegate: AnyObject {
    func openMail(with dataCollector: EmailDataCollector, recipient: String, emailType: EmailType)
    func openScanCardManual()
}

class UnlockUserWalletBottomSheetViewModel: ObservableObject, Identifiable {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.failedScanTracker) private var failedCardScanTracker: FailedScanTrackable

    @Published var isScannerBusy = false
    @Published var error: AlertBinder? = nil
    @Published var actionSheet: ActionSheetBinder?

    private let userWalletModel: UserWalletModel
    private weak var delegate: UnlockUserWalletBottomSheetDelegate?

    init(userWalletModel: UserWalletModel, delegate: UnlockUserWalletBottomSheetDelegate?) {
        self.userWalletModel = userWalletModel
        self.delegate = delegate
    }

    func unlockWithBiometry() {
        Analytics.log(.buttonUnlockAllWithBiometrics)

        runTask(in: self) { viewModel in
            do {
                let context = try await UserWalletBiometricsUnlocker().unlock()
                try viewModel.userWalletRepository.unlock(
                    userWalletId: viewModel.userWalletModel.userWalletId,
                    method: .biometrics(context)
                )
            } catch where error.isCancellationError {
                return
            } catch {
                await runOnMain {
                    viewModel.error = error.alertBinder
                }
            }
        }
    }

    func unlockWithCard() {
        Analytics.beginLoggingCardScan(source: .mainUnlock)
        isScannerBusy = true

        runTask(in: self) { viewModel in
            let cardScanner = CardScannerFactory().makeDefaultScanner()
            let userWalletCardScanner = UserWalletCardScanner(scanner: cardScanner)
            let result = await userWalletCardScanner.scanCard()

            switch result {
            case .error(let error) where error.isCancellationError:
                await runOnMain {
                    viewModel.isScannerBusy = false
                }

            case .error(let error):
                Analytics.logScanError(error, source: .main)
                Analytics.logVisaCardScanErrorIfNeeded(error, source: .main)

                await runOnMain {
                    viewModel.isScannerBusy = false
                    viewModel.error = error.alertBinder
                }

            case .scanTroubleshooting:
                await runOnMain {
                    viewModel.isScannerBusy = false
                    Analytics.log(.cantScanTheCard, params: [.source: .main])
                    viewModel.openTroubleshooting()
                }

            case .success(let cardInfo):
                do {
                    guard let userWalletId = UserWalletId(cardInfo: cardInfo),
                          userWalletId == viewModel.userWalletModel.userWalletId else {
                        throw UserWalletRepositoryError.cardWithWrongUserWalletIdScanned
                    }

                    try viewModel.userWalletRepository.unlock(
                        userWalletId: viewModel.userWalletModel.userWalletId,
                        method: .card(cardInfo)
                    )

                    await runOnMain {
                        viewModel.isScannerBusy = false
                    }

                } catch {
                    await runOnMain {
                        viewModel.isScannerBusy = false
                        viewModel.error = error.alertBinder
                    }
                }

            default:
                await runOnMain {
                    viewModel.isScannerBusy = false
                }
            }
        }
    }

    func openTroubleshooting() {
        let sheet = ActionSheet(
            title: Text(Localization.alertTroubleshootingScanCardTitle),
            message: Text(Localization.alertTroubleshootingScanCardMessage),
            buttons: [
                .default(Text(Localization.alertButtonTryAgain), action: weakify(self, forFunction: UnlockUserWalletBottomSheetViewModel.unlockWithCard)),
                .default(Text(Localization.commonReadMore), action: weakify(self, forFunction: UnlockUserWalletBottomSheetViewModel.openScanCardManual)),
                .default(Text(Localization.alertButtonRequestSupport), action: weakify(self, forFunction: UnlockUserWalletBottomSheetViewModel.requestSupport)),
                .cancel(),
            ]
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.actionSheet = ActionSheetBinder(sheet: sheet)
        }
    }

    func openScanCardManual() {
        Analytics.log(.cantScanTheCardButtonBlog, params: [.source: .main])
        delegate?.openScanCardManual()
    }

    func requestSupport() {
        Analytics.log(.requestSupport, params: [.source: .main])
        failedCardScanTracker.resetCounter()
        delegate?.openMail(with: BaseDataCollector(), recipient: EmailConfig.default.recipient, emailType: .failedToScanCard)
    }
}
