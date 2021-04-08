//
//  DataCollectors.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

protocol EmailDataCollector {
    var dataForEmail: String { get }
    var attachment: Data? { get }
}

extension EmailDataCollector {
    var attachment: Data? { nil }
    
    fileprivate func collectData(from card: Card) -> [EmailCollectedData] {
        [
            EmailCollectedData(type: .card(.cardId), data: card.cardId ?? ""),
            EmailCollectedData(type: .card(.firmwareVersion), data: card.firmwareVersion?.version ?? ""),
            EmailCollectedData(type: .card(.blockchain), data: card.cardData?.blockchainName ?? "")
        ]
    }
    
    fileprivate func formatData(_ data: [EmailCollectedData], appendDeviceInfo: Bool = true) -> String {
        data.reduce("", { $0 + $1.type.title + $1.data + "\n" }) + (appendDeviceInfo ? DeviceInfoProvider.info() : "")
    }
}

class NegativeFeedbackDataCollector: EmailDataCollector {
    
    weak var cardRepository: CardsRepository!
    
    var dataForEmail: String {
        guard let card = cardRepository.lastScanResult.card else { return "" }
        
        return formatData(collectData(from: card))
    }
}


struct SendScreenDataCollector: EmailDataCollector {
    
    unowned var sendViewModel: SendViewModel
    
    var lastError: Error? = nil
    
    var dataForEmail: String {
        let card = sendViewModel.cardViewModel.cardInfo.card
        var data = collectData(from: card)
        if let token = sendViewModel.amountToSend.type.token {
            data.append(EmailCollectedData(type: .card(.token), data: token.symbol))
        }
        
        data.append(contentsOf: [
            EmailCollectedData(type: .error, data: lastError?.localizedDescription ?? "Unknown error"),
            EmailCollectedData(type: .send(.sourceAddress), data: sendViewModel.walletModel.wallet.address),
            EmailCollectedData(type: .send(.destinationAddress), data: sendViewModel.destination),
            EmailCollectedData(type: .send(.amount), data: sendViewModel.amountText),
            EmailCollectedData(type: .send(.fee), data: sendViewModel.sendFee),
        ])
        
        return formatData(data)
    }
    
}

struct DetailsFeedbackDataCollector: EmailDataCollector {
    
    unowned var cardModel: CardViewModel
    
    var dataForEmail: String {
        let card = cardModel.cardInfo.card
        
        var dataToFormat = collectData(from: card)
        
        let signedHashesConsolidated = card.wallets.map { " \(String(describing: $0.curve)) \(String(describing: $0.signedHashes))" }.joined(separator: ";")
        dataToFormat.append(EmailCollectedData(type: .wallet(.signedHashes), data: "\(signedHashesConsolidated)"))
        
        if case let .loaded(walletModels) = cardModel.state {
            for walletModel in walletModels {
                if walletModel.addressNames.count > 1 {
                    var explorerLinks = "Multiple explorers links: "
                    var addresses = "Multiple addresses: "
                    let suffix = " ; \n"
                    walletModel.addressNames.enumerated().forEach {
                        let namePrefix = $0.element + " - "
                        addresses += namePrefix + walletModel.displayAddress(for: $0.offset) + suffix
                        explorerLinks += namePrefix + (walletModel.exploreURL(for: $0.offset)?.absoluteString ?? "") + suffix
                    }
                    explorerLinks.removeLast(suffix.count)
                    addresses.removeLast(suffix.count)
                    dataToFormat.append(EmailCollectedData(type: .wallet(.walletAddress), data: addresses))
                    dataToFormat.append(EmailCollectedData(type: .wallet(.explorerLink), data: explorerLinks))
                } else if walletModel.addressNames.count == 1 {
                    dataToFormat.append(EmailCollectedData(type: .wallet(.walletAddress), data: walletModel.displayAddress(for: 0)))
                    dataToFormat.append(EmailCollectedData(type: .wallet(.explorerLink), data: walletModel.exploreURL(for: 0)?.absoluteString ?? ""))
                }
            }
        }
        return formatData(dataToFormat)
    }
}
