//
//  DataCollectors.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

protocol EmailDataCollector {
    var dataForEmail: String { get }
    var attachment: Data? { get }
}

extension EmailDataCollector {
    var attachment: Data? { nil }
}

class CollectedForEmailDataFormatter {
    static func formatData(_ data: [EmailCollectedData]) -> String {
        data.reduce("", { $0 + $1.type.title + $1.data + "\n" })
    }
}

struct NegativeFeedbackDataCollector: EmailDataCollector {
    
    unowned var cardRepository: CardsRepository
    
    var dataForEmail: String {
        guard let card = cardRepository.lastScanResult.card else { return "" }
        
        return CollectedForEmailDataFormatter.formatData([
            .init(type: .card(.cardId), data: card.cardId ?? ""),
            .init(type: .card(.blockchain), data: card.cardData?.blockchainName ?? ""),
        ]) + DeviceInfoProvider.info()
    }
}

class FailedCardScanDataCollector: EmailDataCollector {
    
    var logger: Logger
    
    var dataForEmail: String {
        "----------\n" + DeviceInfoProvider.info()
    }
    
    var attachment: Data? {
        logger.logFileData
    }
    
    init(logger: Logger) {
        self.logger = logger
    }
}

struct SendScreenDataCollector: EmailDataCollector {
    var dataForEmail: String {
        ""
    }
}

struct SimpleFeedbackDataCollector: EmailDataCollector {
    
    unowned var cardModel: CardViewModel
    
    var dataForEmail: String {
        let card = cardModel.cardInfo.card
        
        var dataToFormat = [
            EmailCollectedData(type: .card(.cardId), data: card.cardId ?? ""),
            EmailCollectedData(type: .card(.firmwareVersion), data: card.firmwareVersion?.version ?? ""),
            EmailCollectedData(type: .card(.blockchain), data: card.cardData?.blockchainName ?? ""),
            EmailCollectedData(type: .wallet(.signedHashes), data: "\(card.walletSignedHashes ?? 0)")
        ]
        
        if case let .loaded(walletModel) = cardModel.state {
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
        
        return CollectedForEmailDataFormatter.formatData(dataToFormat)
            + DeviceInfoProvider.info()
    }
}
