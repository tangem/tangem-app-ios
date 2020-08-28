//
//  TangemSdkService.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class TangemSdkService: ObservableObject {
    var cards = [String: CardViewModel]()
    
    lazy var tangemSdk: TangemSdk = {
        let sdk = TangemSdk()
        return sdk
    }()
    
    func scan(_ completion: @escaping (Result<CardViewModel, Error>) -> Void) {
        tangemSdk.startSession(with: TapScanTask()) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))  //[REDACTED_TODO_COMMENT]
            case .success(let response):
                guard let cid = response.card.cardId else {
                    completion(.failure(TangemSdkError.unknownError))
                    return
                }
                
                let vm = CardViewModel(card: response.card, verifyCardResponse: response.verifyResponse)
                self.cards[cid] = vm
                completion(.success(vm))
            }
        }
    }
}
