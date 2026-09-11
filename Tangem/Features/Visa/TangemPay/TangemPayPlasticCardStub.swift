//
//  TangemPayPlasticCardStub.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation

// [REDACTED_TODO_COMMENT]
//
// A plastic card has no BFF representation yet, so ordering one records it here instead and the UI reads it
// back through `TangemPayCardEntry.plastic`. When the contract lands a plastic card arrives in
// `customer/me` like any other, so it becomes a `TangemPayCard` and this whole layer goes away:
//
//  1. delete this file, `TangemPayCardEntry.plastic` and the `plasticCards` parameter of its `build`
//  2. delete `TangemPayAccount.addOrderedPlasticCard` / `markPlasticCardActivating` and the store property
//  3. point the card-management and activation screens at the `TangemPayCard` instead
//
// Everything above is unreachable unless `Feature.tangemPayPlastic` is on — see `addOrderedPlasticCard`.
struct TangemPayPlasticCardStub: Identifiable, Hashable {
    enum Stage {
        case delivering
        case activating
    }

    let id: String
    let email: String?
    let activationImageURL: URL?
    var stage: Stage
}

final class TangemPayPlasticCardStubStore {
    var cards: [TangemPayPlasticCardStub] {
        cardsSubject.value
    }

    var cardsPublisher: AnyPublisher<[TangemPayPlasticCardStub], Never> {
        cardsSubject.eraseToAnyPublisher()
    }

    private let cardsSubject = CurrentValueSubject<[TangemPayPlasticCardStub], Never>([])

    func add(email: String?, activationImageURL: URL?) {
        let card = TangemPayPlasticCardStub(
            id: UUID().uuidString,
            email: email,
            activationImageURL: activationImageURL,
            stage: .delivering
        )

        cardsSubject.send(cards + [card])
    }

    func markActivating(id: String) {
        var updated = cards

        guard let index = updated.firstIndex(where: { $0.id == id }) else { return }

        updated[index].stage = .activating
        cardsSubject.send(updated)
    }
}
