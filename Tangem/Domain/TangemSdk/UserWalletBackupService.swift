//
//  UserWalletBackupService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemFoundation

/// App-side facade over TangemSdk's `BackupService`.
///
/// Wraps the SDK backup ceremony and reports the resulting card backup state to the back-end
/// (best-effort, non-blocking) so the app talks to a single backup entry point.
final class UserWalletBackupService {
    static var maxBackupCardsCount: Int { BackupService.maxBackupCardsCount }

    @Injected(\.userWalletCardsBackupStatusReportService) private var reportService: UserWalletCardsBackupStatusReportService

    private let backupService: BackupService

    /// The primary card's info, used to derive the wallet id / seed usage for reporting.
    private var cardInfo: CardInfo?

    init(backupService: BackupService) {
        self.backupService = backupService
    }

    // MARK: - State

    var currentState: BackupService.State { backupService.currentState }
    var primaryCard: PrimaryCard? { backupService.primaryCard }
    var backupCards: [BackupCard] { backupService.backupCards }
    var addedBackupCardsCount: Int { backupService.addedBackupCardsCount }
    var canAddBackupCards: Bool { backupService.canAddBackupCards }
    var hasIncompletedBackup: Bool { backupService.hasIncompletedBackup }
    var primaryCardIsSet: Bool { backupService.primaryCardIsSet }

    var config: Config {
        get { backupService.config }
        set { backupService.config = newValue }
    }

    // MARK: - Operations

    func setPrimaryCard(cardInfo: CardInfo) {
        self.cardInfo = cardInfo

        if let primaryCard = cardInfo.primaryCard {
            backupService.setPrimaryCard(primaryCard)
            reportPrimaryCard()
        }
    }

    func readPrimaryCard(cardId: String, completion: @escaping CompletionResult<Void>) {
        backupService.readPrimaryCard(cardId: cardId, completion: completion)
    }

    func addBackupCard(completion: @escaping CompletionResult<Card>) {
        backupService.addBackupCard { [weak self] result in
            self?.reportAddBackupCard(result: result)
            completion(result)
        }
    }

    func proceedBackup(completion: @escaping CompletionResult<Card>) {
        backupService.proceedBackup { [weak self] result in
            self?.reportProceedBackup(result: result)
            completion(result)
        }
    }

    func setAccessCode(_ code: String) throws {
        try backupService.setAccessCode(code)
    }

    func discardIncompletedBackup() {
        backupService.discardIncompletedBackup()
    }
}

// MARK: - Backup-state reporting

private extension UserWalletBackupService {
    func reportPrimaryCard() {
        report()
    }

    /// A backup card was linked on the "add backup" screen.
    func reportAddBackupCard(result: Result<Card, TangemSdkError>) {
        switch result {
        case .success(let card):
            report(currentCard: card)
        case .failure:
            // The card wasn't linked, so there is nothing to report.
            break
        }
    }

    /// A finalization step completed. On failure the error is attached to the card being finalized.
    func reportProceedBackup(result: Result<Card, TangemSdkError>) {
        switch result {
        case .success(let card):
            report(currentCard: card)
        case .failure(let error):
            report(error: error)
        }
    }

    /// Builds the whole wallet's card backup state and reports it to the back-end (best-effort, non-blocking).
    ///
    /// `currentCard` is the card returned by the just-completed SDK step; the matching backup card reports
    /// its real curves / backup status from it (they can differ from the primary's).
    func report(currentCard: Card? = nil, error: TangemSdkError? = nil) {
        guard let cardInfo else {
            AppLogger.error(error: "CardInfo not found")
            return
        }

        guard let userWalletId = UserWalletId(cardInfo: cardInfo) else {
            AppLogger.error(error: "UserWalletId not found")
            return
        }

        guard let primaryCard = backupService.primaryCard else {
            AppLogger.error(error: "PrimaryCard not found")
            return
        }

        let failure: CardFailure? = {
            if let cardId = currentlyProcessedCardId, let error {
                return CardFailure(cardId: cardId, error: error)
            }

            return nil
        }()

        let primaryStatus = makePrimaryCardStatus(primaryCard, failure: failure)

        let backupStatuses = backupService.backupCards.enumerated().map { index, backupCard in
            let role = UserWalletCardBackupStatus.Role.backup(index: index + 1)

            if let currentCard, currentCard.cardId == backupCard.cardId {
                return makeCardStatus(currentCard, role: role, failure: failure)
            }

            let isFinalized = backupService.currentState.isBackupFinalized(backupIndex: index)
            return makeBackupCardStatus(
                backupCard,
                role: role,
                isFinalized: isFinalized,
                primaryCardCurves: primaryCard.walletCurves,
                failure: failure
            )
        }

        let isImported = cardInfo.card.wallets.contains { $0.isImported == true }
        let cards = [primaryStatus] + backupStatuses
        let status = UserWalletCardsBackupStatus(isImported: isImported, cards: cards)
        reportService.report(status: status, userWalletId: userWalletId.stringValue)
    }

    /// The primary always reports its own created curves; its status comes from the ceremony state.
    func makePrimaryCardStatus(_ primaryCard: PrimaryCard, failure: CardFailure?) -> UserWalletCardBackupStatus {
        let isFinalized = backupService.currentState.isPrimaryFinalized
        let error = failure?.cardId == primaryCard.cardId ? failure?.error : nil

        return UserWalletCardBackupStatus(
            cardId: primaryCard.cardId,
            cardPublicKey: primaryCard.cardPublicKey,
            role: .primary,
            backupStatus: isFinalized ? .active : .noBackup,
            curves: primaryCard.walletCurves,
            errorCode: error?.code,
            errorMessage: error?.message
        )
    }

    /// The card returned by the just-completed SDK step: reports its real curves and backup status.
    func makeCardStatus(_ card: Card, role: UserWalletCardBackupStatus.Role, failure: CardFailure?) -> UserWalletCardBackupStatus {
        let error = failure?.cardId == card.cardId ? failure?.error : nil

        return UserWalletCardBackupStatus(
            cardId: card.cardId,
            cardPublicKey: card.cardPublicKey,
            role: role,
            backupStatus: mapBackupStatus(card.backupStatus),
            curves: card.wallets.map(\.curve),
            errorCode: error?.code,
            errorMessage: error?.message
        )
    }

    /// A linked backup card we have no fresh `Card` for. Once finalized it inherits the primary's created
    /// curves; before that it has none. Status is derived from the ceremony state.
    func makeBackupCardStatus(
        _ backupCard: BackupCard,
        role: UserWalletCardBackupStatus.Role,
        isFinalized: Bool,
        primaryCardCurves: [EllipticCurve],
        failure: CardFailure?
    ) -> UserWalletCardBackupStatus {
        let error = failure?.cardId == backupCard.cardId ? failure?.error : nil

        return UserWalletCardBackupStatus(
            cardId: backupCard.cardId,
            cardPublicKey: backupCard.cardPublicKey,
            role: role,
            backupStatus: isFinalized ? .active : .noBackup,
            curves: isFinalized ? primaryCardCurves : [],
            errorCode: error?.code,
            errorMessage: error?.message
        )
    }

    func mapBackupStatus(_ status: Card.BackupStatus?) -> UserWalletCardBackupStatus.BackupStatus? {
        switch status {
        case .noBackup: return .noBackup
        case .cardLinked: return .cardLinked
        case .active: return .active
        case nil: return nil
        }
    }

    /// The card currently being finalized — used to attribute a finalize error.
    var currentlyProcessedCardId: String? {
        switch backupService.currentState {
        case .finalizingPrimaryCard:
            return backupService.primaryCard?.cardId
        case .finalizingBackupCard(let index):
            // `index` is 1-based (the card being finalized), so shift to a 0-based array index.
            return backupService.backupCards[safe: index - 1]?.cardId
        case .preparing, .finished:
            return nil
        }
    }
}

private struct CardFailure {
    let cardId: String
    let error: TangemSdkError
}

// MARK: - BackupService.State helpers

private extension BackupService.State {
    var isPrimaryFinalized: Bool {
        switch self {
        case .finalizingBackupCard, .finished: return true
        case .preparing, .finalizingPrimaryCard: return false
        }
    }

    /// `index` is 0-based. During `.finalizingBackupCard(currentIndex)` the 1-based `currentIndex`
    /// points at the card being finalized next, so any backup with a lower position is already active.
    func isBackupFinalized(backupIndex index: Int) -> Bool {
        switch self {
        case .finished: return true
        case .finalizingBackupCard(let currentIndex): return index + 1 < currentIndex
        case .preparing, .finalizingPrimaryCard: return false
        }
    }
}
