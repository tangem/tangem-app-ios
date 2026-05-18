//
//  TangemPayCardEntry.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPay
import TangemVisa

enum TangemPayCardEntry: Identifiable {
    case issued(TangemPayCard)
    case issuing(Issuing)

    enum Issuing {
        case card(TangemPayCard)
        case pendingProductInstance(VisaCustomerInfoResponse.ProductInstance)
        case order(TangemPayOrderResponse)
    }

    var id: String {
        switch self {
        case .issued(let card):
            card.cardId
        case .issuing(.card(let card)):
            card.cardId
        case .issuing(.pendingProductInstance(let pi)):
            pi.id
        case .issuing(.order(let order)):
            order.id
        }
    }

    var isIssuing: Bool {
        if case .issuing = self { true } else { false }
    }

    var card: TangemPayCard? {
        switch self {
        case .issued(let card), .issuing(.card(let card)):
            card
        case .issuing(.pendingProductInstance), .issuing(.order):
            nil
        }
    }

    var pendingProductInstance: VisaCustomerInfoResponse.ProductInstance? {
        if case .issuing(.pendingProductInstance(let pi)) = self { pi } else { nil }
    }

    var order: TangemPayOrderResponse? {
        if case .issuing(.order(let order)) = self { order } else { nil }
    }
}

extension TangemPayCardEntry {
    static func build(
        cards: [TangemPayCard],
        pendingProductInstances: [VisaCustomerInfoResponse.ProductInstance],
        activeIssueOrders: [TangemPayOrderResponse]
    ) -> [TangemPayCardEntry] {
        var entries: [TangemPayCardEntry] = []
        entries.reserveCapacity(cards.count + pendingProductInstances.count + activeIssueOrders.count)

        for card in cards {
            entries.append(card.isIssuing ? .issuing(.card(card)) : .issued(card))
        }
        let pendingPIIds = Set(pendingProductInstances.map(\.id))
        let cardPIIds = Set(cards.map(\.productInstance.id))
        for pi in pendingProductInstances {
            entries.append(.issuing(.pendingProductInstance(pi)))
        }
        for order in activeIssueOrders {
            if let pid = order.data?.productInstanceId,
               pendingPIIds.contains(pid) || cardPIIds.contains(pid) {
                continue
            }
            entries.append(.issuing(.order(order)))
        }
        return entries
    }
}
