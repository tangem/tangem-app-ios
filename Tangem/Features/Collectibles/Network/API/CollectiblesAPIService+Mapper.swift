//
//  CollectiblesAPIService+Mapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

extension CollectiblesAPIService {
    enum Mapper {
        static func mapToLoreCatalogue(_ response: CollectiblesDTO.MachineCategoriesResponse) -> CollectiblesLoreCatalogue {
            let lores = response.categories.map { category in
                CollectiblesLore(id: category.id, title: category.name, packsCount: category.machinesQuantity)
            }

            return CollectiblesLoreCatalogue(lores: lores, totalPacksCount: response.totalMachinesQuantity)
        }

        static func mapToPack(_ machine: CollectiblesDTO.Machine) -> CollectiblesPack {
            CollectiblesPack(
                id: machine.externalId,
                name: mapToName(machine),
                loreID: machine.categoryId,
                price: machine.price / Constants.centsScale,
                currencyCode: AppConstants.usdCurrencyCode,
                buybackRate: Decimal(machine.instantBuybackPercent) / Constants.percentScale,
                artworkURL: machine.image.flatMap(URL.init)
            )
        }

        static func mapToMachine(_ machine: CollectiblesDTO.Machine) -> CollectiblesMachine {
            CollectiblesMachine(
                name: mapToName(machine),
                artworkURL: machine.image.flatMap(URL.init),
                price: machine.price / Constants.centsScale,
                cardsPerPack: machine.contains,
                buybackRate: Decimal(machine.instantBuybackPercent) / Constants.percentScale,
                expectedValue: machine.expectedValue,
                tiers: mapTiers(of: machine)
            )
        }

        static func mapToPrizePoolPage(_ response: CollectiblesDTO.MachineNftsResponse) -> CollectiblesPrizePoolPage {
            CollectiblesPrizePoolPage(prizes: response.nfts.map(mapToPrize), hasNext: response.hasMore)
        }
    }
}

// MARK: - Private logic

private extension CollectiblesAPIService.Mapper {
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

        return Decimal(range.start) ... Decimal(range.end)
    }

    enum Constants {
        /// `price`, `feeAmount` and `insured_value` arrive in cents (`price: 5000` is $50);
        /// `expectedValue` and `tierRanges` already come in whole dollars and are taken as they are.
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
