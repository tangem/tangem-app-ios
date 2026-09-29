//
//  TangemPayCardEntry.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemPay
import TangemVisa

enum TangemPayCardEntry: Identifiable {
    case issued(TangemPayCard)
    case issuing(Issuing)
    case plastic(Plastic)

    enum Issuing {
        case card(TangemPayCard)
        case pendingProductInstance(VisaCustomerInfoResponse.ProductInstance)
        case order(TangemPayOrderResponse)
    }

    enum Plastic: Equatable {
        case delivering(order: TangemPayOrderResponse)
        case awaitingActivation(card: TangemPayCard, isActivating: Bool)

        enum Stage {
            case delivering
            case activating
        }

        var stage: Stage {
            switch self {
            case .delivering:
                .delivering
            case .awaitingActivation(_, let isActivating):
                isActivating ? .activating : .delivering
            }
        }

        var deliveredCard: TangemPayCard? {
            if case .awaitingActivation(let card, _) = self { card } else { nil }
        }

        var isDelivering: Bool {
            if case .delivering = self { true } else { false }
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id && lhs.stage == rhs.stage && lhs.productInstanceId == rhs.productInstanceId
        }

        fileprivate var id: String {
            switch self {
            case .delivering(let order):
                order.id
            case .awaitingActivation(let card, _):
                card.cardId
            }
        }

        var productInstanceId: String? {
            switch self {
            case .delivering(let order):
                order.data?.productInstanceId
            case .awaitingActivation(let card, _):
                card.productInstance.id
            }
        }
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
        case .plastic(let plastic):
            plastic.id
        }
    }

    var productInstanceId: String? {
        switch self {
        case .issued(let card), .issuing(.card(let card)):
            card.productInstance.id
        case .issuing(.pendingProductInstance(let pi)):
            pi.id
        case .issuing(.order(let order)):
            order.data?.productInstanceId
        case .plastic(let plastic):
            plastic.productInstanceId
        }
    }

    var isIssuing: Bool {
        if case .issuing = self { true } else { false }
    }

    var isGhost: Bool {
        order?.isAwaitingDeposit == true
    }

    var card: TangemPayCard? {
        switch self {
        case .issued(let card), .issuing(.card(let card)):
            card
        case .issuing(.pendingProductInstance), .issuing(.order), .plastic:
            nil
        }
    }

    var pendingProductInstance: VisaCustomerInfoResponse.ProductInstance? {
        if case .issuing(.pendingProductInstance(let pi)) = self { pi } else { nil }
    }

    var order: TangemPayOrderResponse? {
        if case .issuing(.order(let order)) = self { order } else { nil }
    }

    var plasticCard: Plastic? {
        if case .plastic(let plastic) = self { plastic } else { nil }
    }
}

extension TangemPayCardEntry {
    static func build(
        cards: [TangemPayCard],
        pendingProductInstances: [VisaCustomerInfoResponse.ProductInstance],
        activeIssueOrders: [TangemPayOrderResponse],
        activatingProductInstanceIds: Set<String>,
        hiddenSourceProductInstanceIds: Set<String>
    ) -> [TangemPayCardEntry] {
        let isPlasticEnabled = FeatureProvider.isAvailable(.tangemPayPlastic)

        var entries: [TangemPayCardEntry] = []
        entries.reserveCapacity(cards.count + pendingProductInstances.count + activeIssueOrders.count)

        for card in cards {
            if hiddenSourceProductInstanceIds.contains(card.productInstance.id) { continue }
            if isPlasticEnabled, card.isAwaitingActivation {
                entries.append(.plastic(.awaitingActivation(
                    card: card,
                    isActivating: activatingProductInstanceIds.contains(card.productInstance.id)
                )))
            } else {
                entries.append(card.isIssuing ? .issuing(.card(card)) : .issued(card))
            }
        }
        let pendingPIIds = Set(pendingProductInstances.map(\.id))
        let cardPIIds = Set(cards.map(\.productInstance.id))
        for pi in pendingProductInstances.sorted(by: { $0.id < $1.id }) {
            if cardPIIds.contains(pi.id) { continue }
            entries.append(.issuing(.pendingProductInstance(pi)))
        }
        // A plastic order carries no `product_instance_id` to match its card by, and only one runs at a time.
        let hasDeliveredPlasticCard = cards.contains(where: \.isAwaitingActivation)
        let plasticDeliveringOrderTypes = TangemPayOrderType.plasticDeliveringFamily
        for order in activeIssueOrders.sorted(by: { $0.id < $1.id }) {
            if let pid = order.data?.productInstanceId,
               pendingPIIds.contains(pid) || cardPIIds.contains(pid) {
                continue
            }
            guard isPlasticEnabled, plasticDeliveringOrderTypes.contains(order.type) else {
                entries.append(.issuing(.order(order)))
                continue
            }

            if !hasDeliveredPlasticCard {
                entries.append(.plastic(.delivering(order: order)))
            }
        }
        return entries
    }
}
