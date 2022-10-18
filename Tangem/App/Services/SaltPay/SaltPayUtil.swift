//
//  SaltPayUtil.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct SaltPayUtil {
    func isSaltPayCard(batchId: String, cardId: String) -> Bool {
        isPrimaryCard(batchId: batchId) || isBackupCard(cardId: cardId)
    }

    func isPrimaryCard(batchId: String) -> Bool {
        primaryCardBatches.contains(batchId)
    }

    func isBackupCard(cardId: String) -> Bool {
        if backupCardIds.contains(cardId) {
            return true
        }

        if backupCardRanges.contains(cardId) {
            return true
        }

        return false
    }
}

extension SaltPayUtil {
    private var primaryCardBatches: [String] {
        [
            "AE02",
            "AE03",
            "FF03",
        ]
    }

    var backupCardIds: [String] {
        [
            "AC01000000033503",
            "AC01000000033594",
            "AC01000000033586",
            "AC01000000034477",
            "AC01000000032760",
            "AC01000000033867",
            "AC01000000032653",
            "AC01000000032752",
            "AC01000000034485",
            "AC01000000033644",
            "AC01000000037454",
            "AC01000000037462",
            "AC03000000076070",
            "AC03000000076088",
            "AC03000000076096",
            "AC03000000076104",
            "AC03000000076112",
            "AC03000000076120",
            "AC03000000076138",
            "AC03000000076146",
            "AC03000000076153",
            "AC03000000076161",
            "AC03000000076179",
            "AC03000000076187",
            "AC03000000076195",
            "AC03000000076203",
            "AC03000000076211",
            "AC03000000076229",
        ]
    }

    var backupCardRanges: [CardIdRange] {
        [
            .init(start: "AC05000000000003", end: "AC05000000023997")!, // start and end batches must be equal
            .init(start: "FF04000000000000", end: "FF04999999999999")!, // start and end batches must be equal
        ]
    }
}
