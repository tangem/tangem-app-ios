//
//  PromoCampaignFlowState.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct PromoCampaignFlowState {
    private(set) var sheet: Sheet = .notEnqueued
    private(set) var isSafariPresented = false
    private(set) var isEnrolling = false
    private(set) var isSheetsDisplayingPausedForResult = false
    private(set) var isFinished = false
    private(set) var isScanningOrUnlocking = false
    private(set) var deferredResult: Result?

    func isStale(isSheetAlive: Bool) -> Bool {
        sheet == .enqueued && !isSheetAlive && !isSafariPresented && !isEnrolling
    }

    mutating func enqueueSheet() {
        guard sheet == .notEnqueued else {
            return
        }

        sheet = .enqueued
    }

    mutating func closeSheet() -> Bool {
        guard sheet == .enqueued else {
            return false
        }

        sheet = .closed
        return true
    }

    mutating func openSafari() -> Bool {
        guard sheet == .enqueued, !isEnrolling, !isSafariPresented else {
            return false
        }

        isSafariPresented = true
        return true
    }

    mutating func closeSafari(isSheetAlive: Bool) -> Bool {
        guard isSafariPresented else {
            return false
        }

        isSafariPresented = false

        guard isStale(isSheetAlive: isSheetAlive) else {
            return false
        }

        sheet = .closed
        return true
    }

    mutating func startEnrollment() -> Bool {
        guard sheet == .enqueued, !isEnrolling, !isSafariPresented else {
            return false
        }

        isEnrolling = true
        return true
    }

    mutating func finishEnrollment(isSheetAlive: Bool) -> Bool {
        guard isEnrolling else {
            return false
        }

        let ownsSheet = sheet == .enqueued && isSheetAlive

        isEnrolling = false
        sheet = .closed

        return ownsSheet
    }

    mutating func pauseSheetsForResult() {
        isSheetsDisplayingPausedForResult = true
    }

    mutating func receiveResult(_ result: Result) -> Result? {
        guard !isFinished else {
            return nil
        }

        guard !isScanningOrUnlocking else {
            deferredResult = result
            return nil
        }

        return result
    }

    mutating func changeScanningOrUnlocking(isActive: Bool) -> Result? {
        isScanningOrUnlocking = isActive

        guard !isActive, !isFinished, let deferredResult else {
            return nil
        }

        self.deferredResult = nil
        return deferredResult
    }

    mutating func finish() -> Bool {
        guard !isFinished else {
            return false
        }

        isFinished = true
        deferredResult = nil
        return true
    }
}

// MARK: - Result

extension PromoCampaignFlowState {
    struct Result: Equatable {
        let outcome: PromoCampaignEnrollmentOutcome
        let campaign: PromoCampaign
    }
}

// MARK: - Sheet

extension PromoCampaignFlowState {
    enum Sheet {
        case notEnqueued
        case enqueued
        case closed
    }
}
