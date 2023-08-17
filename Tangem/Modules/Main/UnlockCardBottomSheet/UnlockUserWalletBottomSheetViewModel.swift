//
//  UnlockUserWalletBottomSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol UnlockUserWalletDelegate: AnyObject {
    func unlockedWithBiometry()
    func userWalletUnlocked(_ userWalletModel: UserWalletModel)
    func showTroubleshooting()
}

class UnlockUserWalletBottomSheetViewModel: ObservableObject, Identifiable {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    @Published var isScannerBusy = false
    @Published var error: AlertBinder? = nil

    private let userWalletModel: UserWalletModel
    private weak var delegate: UnlockUserWalletDelegate?

    init(userWalletModel: UserWalletModel, delegate: UnlockUserWalletDelegate?) {
        self.userWalletModel = userWalletModel
        self.delegate = delegate
    }

    func unlockWithBiometry() {
        // [REDACTED_TODO_COMMENT]
        //        Analytics.log(.buttonUnlockAllWithFaceID)

        userWalletRepository.unlock(with: .biometry) { [weak self] result in
            switch result {
            case .error(let error), .partial(_, let error):
                self?.error = error.alertBinder
            case .success:
                self?.delegate?.unlockedWithBiometry()
            default:
                break
            }
        }
    }

    func unlockWithCard() {
        // [REDACTED_TODO_COMMENT]
        Analytics.beginLoggingCardScan(source: .myWalletsUnlock)
        isScannerBusy = true
        userWalletRepository.unlock(with: .card(userWallet: userWalletModel.userWallet)) { [weak self] result in
            DispatchQueue.main.async {
                self?.isScannerBusy = false
                switch result {
                case .success(let unlockedModel):
                    self?.delegate?.userWalletUnlocked(unlockedModel)
                case .error(let error), .partial(_, let error):
                    self?.error = error.alertBinder
                case .troubleshooting:
                    self?.delegate?.showTroubleshooting()
                default:
                    break
                }
            }
        }
    }
}
