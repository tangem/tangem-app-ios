//
//  CollectiblesAPIService+Mapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemCollectibles
import TangemFoundation

extension CollectiblesAPIService {
    enum Mapper {
        static func mapToLoreCatalogue(_ response: CollectiblesDTO.MachineCategoriesResponse) -> CollectiblesLoreCatalogue {
            let lores = response.categories.map { category in
                CollectiblesLore(id: category.id, title: category.name, packsCount: category.machinesQuantity)
            }

            return CollectiblesLoreCatalogue(lores: lores, totalPacksCount: response.totalMachinesQuantity)
        }

        static func mapToTurboMode(_ turboMode: CollectiblesTurboMode) -> CollectiblesDTO.TurboMode? {
            switch turboMode {
            case .off: nil
            case .on(let buybackAddress): CollectiblesDTO.TurboMode(enabled: true, buybackAddress: buybackAddress)
            }
        }

        static func mapToPack(_ machine: CollectiblesDTO.Machine) -> CollectiblesPack {
            CollectiblesPack(
                id: machine.externalId,
                loreID: machine.categoryId,
                currencyCode: AppConstants.usdCurrencyCode,
                machine: mapToMachine(machine)
            )
        }

        static func mapToMachine(_ machine: CollectiblesDTO.Machine) -> CollectiblesMachine {
            CollectiblesMachine(
                name: mapToName(machine),
                artworkURL: machine.image.flatMap(URL.init),
                price: machine.price / Constants.centsScale,
                platformFee: machine.feeAmount / Constants.centsScale,
                cardsPerPack: machine.contains,
                buybackRate: Decimal(machine.instantBuybackPercent) / Constants.percentScale,
                expectedValue: machine.expectedValue / Constants.centsScale,
                tiers: mapTiers(of: machine),
                openingVideoURL: machine.videoOpenPack.flatMap(URL.init)
            )
        }

        static func mapToPrizePoolPage(_ response: CollectiblesDTO.MachineNftsResponse) -> CollectiblesPrizePoolPage {
            CollectiblesPrizePoolPage(prizes: response.nfts.map(mapToPrize), hasNext: response.hasMore)
        }

        static func mapToGeneratedPurchase(
            _ response: CollectiblesDTO.GeneratePurchaseTxResponse
        ) throws -> CollectiblesGeneratedPurchase {
            let txData = response.txData

            return CollectiblesGeneratedPurchase(
                txID: response.txID,
                purchase: CollectiblesPackPurchase(
                    memo: txData.memo,
                    usdcMint: txData.fromContractAddress,
                    amount: try mapToBaseUnits(txData.fromAmount),
                    feeAmount: try mapToBaseUnits(txData.feeAmount)
                )
            )
        }

        static func mapToPurchaseTransaction(
            _ transaction: CollectiblesDTO.PurchaseTransaction
        ) -> CollectiblesPurchaseTransaction {
            CollectiblesPurchaseTransaction(
                status: mapToPurchaseStatus(transaction),
                wonCard: transaction.nftWon.map(mapToWonCard)
            )
        }

        static func mapToPurchaseStatus(
            _ transaction: CollectiblesDTO.PurchaseTransaction
        ) -> CollectiblesPurchaseStatus {
            switch transaction.status {
            case "created": .created
            case "waiting-tx-hash": .waitingTxHash
            case "purchase-tx-hash", "purchase-tx-sent": .purchaseTxHash
            case "waiting-for-payment": .waitingForPayment
            case "expired": .expired
            case "pack-purchased": .packPurchased
            case "pack-opening-error": .packOpeningError
            case "refunded": .refunded
            case "auto-buybacked": .autoBuybacked
            case "pack-opened": .packOpened
            case "nft-received": .nftReceived
            case "manually-buybacked": .manuallyBuybacked
            case "paused": .paused
            default: .unknown(transaction.status)
            }
        }
    }
}

// MARK: - Private logic

private extension CollectiblesAPIService.Mapper {
    static func mapToBaseUnits(_ amount: String) throws -> UInt64 {
        guard let value = UInt64(amount) else {
            let context = DecodingError.Context(codingPath: [], debugDescription: "Not a base-unit amount: \(amount)")
            throw CollectiblesAPIService.Error.decoding(.dataCorrupted(context))
        }

        return value
    }

    static func mapToWonCard(_ nft: CollectiblesDTO.NftWon) -> CollectiblesWonCard {
        CollectiblesWonCard(
            imageFrontURL: nft.imageFront.flatMap(URL.init),
            imageBackURL: nft.imageBack.flatMap(URL.init),
            gradingCompany: nft.gradingCompany?.trimmed().nilIfEmpty,
            grade: nft.theGrade?.trimmed().nilIfEmpty,
            gradingID: nft.gradingID?.trimmed().nilIfEmpty,
            rarity: nft.rarity.flatMap(CollectiblesMachine.Tier.init),
            year: nft.year?.trimmed().nilIfEmpty,
            set: nft.set?.trimmed().nilIfEmpty,
            serialNumber: nft.serialNumber?.trimmed().nilIfEmpty,
            insuredValue: nft.insuredValue.map { $0 / Constants.centsScale }
        )
    }

    static func mapToPrize(_ nft: CollectiblesDTO.MachineNft) -> CollectiblesPrize {
        CollectiblesPrize(
            id: nft.id,
            name: nft.name,
            imageURL: nft.image.flatMap(URL.init),
            grade: mapToGrade(nft),
            insuredValue: nft.insuredValue.map { $0 / Constants.centsScale }
        )
    }

    /// The grader and the grade travel as separate fields and either may come empty rather than absent; the label
    /// needs both, a company without a grade says nothing.
    static func mapToGrade(_ nft: CollectiblesDTO.MachineNft) -> String? {
        guard
            let company = nft.gradingCompany?.trimmed().nilIfEmpty,
            let grade = nft.gradeNum?.trimmed().nilIfEmpty
        else {
            return nil
        }

        return "\(company) \(grade)"
    }

    static func mapToName(_ machine: CollectiblesDTO.Machine) -> String {
        machine.shortName.isEmpty ? machine.name : machine.shortName
    }

    /// A tier the machine does not carry is absent from every dictionary (a missing key or an explicit null),
    /// so a tier with neither odds nor a value range is dropped rather than rendered blank.
    static func mapTiers(of machine: CollectiblesDTO.Machine) -> [CollectiblesMachine.TierStats] {
        CollectiblesMachine.Tier.allCases.compactMap { tier in
            let odds = machine.odds.value(for: tier)
            let valueRange = mapValueRange(machine.tierRanges.value(for: tier))

            guard odds != nil || valueRange != nil else { return nil }

            return CollectiblesMachine.TierStats(
                tier: tier,
                odds: odds.map { Decimal($0) / Constants.percentScale },
                valueRange: valueRange
            )
        }
    }

    /// Bounds arrive from the partner: an inverted pair would trap `ClosedRange`, so it is dropped as bad data.
    static func mapValueRange(_ range: CollectiblesDTO.Machine.TierRange?) -> ClosedRange<Decimal>? {
        guard let range, range.start <= range.end else { return nil }

        return Decimal(range.start) / Constants.centsScale ... Decimal(range.end) / Constants.centsScale
    }

    enum Constants {
        /// `price`, `feeAmount`, `expectedValue`, `tierRanges` and `insured_value` arrive in cents
        /// (`price: 5000` is $50).
        static let centsScale = Decimal(100)
        /// `instantBuybackPercent` is whole percent (85), the domain rate is a fraction (0.85).
        static let percentScale = Decimal(100)
    }
}

private extension CollectiblesDTO.Machine.Tiers {
    func value(for tier: CollectiblesMachine.Tier) -> Value? {
        switch tier {
        case .common: common
        case .uncommon: uncommon
        case .rare: rare
        case .epic: epic
        case .legendary: legendary
        }
    }
}
