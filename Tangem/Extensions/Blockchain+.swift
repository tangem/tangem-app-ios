//
//  Blockchain+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemAssets

extension Blockchain {
    var iconAsset: ImageType {
        iconAsset(filled: false)
    }

    var iconAssetFilled: ImageType {
        iconAsset(filled: true)
    }

    private func iconAsset(filled: Bool) -> ImageType {
        switch self {
        case .bitcoin:
            filled ? Tokens.bitcoinFill : Tokens.bitcoin
        case .litecoin:
            filled ? Tokens.litecoinFill : Tokens.litecoin
        case .stellar:
            filled ? Tokens.stellarFill : Tokens.stellar
        case .ethereum:
            filled ? Tokens.ethereumFill : Tokens.ethereum
        case .ethereumPoW:
            filled ? Tokens.ethereumpowFill : Tokens.ethereumpow
        case .disChain:
            filled ? Tokens.dischainFill : Tokens.dischain
        case .ethereumClassic:
            filled ? Tokens.ethereumclassicFill : Tokens.ethereumclassic
        case .rsk:
            filled ? Tokens.rskFill : Tokens.rsk
        case .bitcoinCash:
            filled ? Tokens.bitcoincashFill : Tokens.bitcoincash
        case .binance:
            filled ? Tokens.bscFill : Tokens.bsc
        case .cardano:
            filled ? Tokens.cardanoFill : Tokens.cardano
        case .xrp:
            filled ? Tokens.xrpFill : Tokens.xrp
        case .ducatus:
            filled ? Tokens.ducatusFill : Tokens.ducatus
        case .tezos:
            filled ? Tokens.tezosFill : Tokens.tezos
        case .dogecoin:
            filled ? Tokens.dogecoinFill : Tokens.dogecoin
        case .bsc:
            filled ? Tokens.bscFill : Tokens.bsc
        case .polygon:
            filled ? Tokens.polygonFill : Tokens.polygon
        case .avalanche:
            filled ? Tokens.avalancheFill : Tokens.avalanche
        case .solana:
            filled ? Tokens.solanaFill : Tokens.solana
        case .fantom:
            filled ? Tokens.fantomFill : Tokens.fantom
        case .polkadot:
            filled ? Tokens.polkadotFill : Tokens.polkadot
        case .kusama:
            filled ? Tokens.kusamaFill : Tokens.kusama
        case .azero:
            filled ? Tokens.azeroFill : Tokens.azero
        case .tron:
            filled ? Tokens.tronFill : Tokens.tron
        case .arbitrum:
            filled ? Tokens.arbitrumFill : Tokens.arbitrum
        case .dash:
            filled ? Tokens.dashFill : Tokens.dash
        case .gnosis:
            filled ? Tokens.gnosisFill : Tokens.gnosis
        case .optimism:
            filled ? Tokens.optimismFill : Tokens.optimism
        case .ton:
            filled ? Tokens.tonFill : Tokens.ton
        case .kava:
            filled ? Tokens.kavaFill : Tokens.kava
        case .kaspa:
            filled ? Tokens.kaspaFill : Tokens.kaspa
        case .ravencoin:
            filled ? Tokens.ravencoinFill : Tokens.ravencoin
        case .cosmos:
            filled ? Tokens.cosmosFill : Tokens.cosmos
        case .terraV1:
            filled ? Tokens.terrav1Fill : Tokens.terrav1
        case .terraV2:
            filled ? Tokens.terrav2Fill : Tokens.terrav2
        case .cronos:
            filled ? Tokens.cronosFill : Tokens.cronos
        case .telos:
            filled ? Tokens.telosFill : Tokens.telos
        case .octa:
            filled ? Tokens.octaFill : Tokens.octa
        case .chia:
            filled ? Tokens.chiaFill : Tokens.chia
        case .near:
            filled ? Tokens.nearFill : Tokens.near
        case .decimal:
            filled ? Tokens.decimalFill : Tokens.decimal
        case .veChain:
            filled ? Tokens.vechainFill : Tokens.vechain
        case .xdc:
            filled ? Tokens.xdcFill : Tokens.xdc
        case .algorand:
            filled ? Tokens.algorandFill : Tokens.algorand
        case .shibarium:
            filled ? Tokens.shibariumFill : Tokens.shibarium
        case .aptos:
            filled ? Tokens.aptosFill : Tokens.aptos
        case .hedera:
            filled ? Tokens.hederaFill : Tokens.hedera
        case .areon:
            filled ? Tokens.areonFill : Tokens.areon
        case .playa3ullGames:
            filled ? Tokens.playa3ullgamesFill : Tokens.playa3ullgames
        case .pulsechain:
            filled ? Tokens.pulsechainFill : Tokens.pulsechain
        case .aurora:
            filled ? Tokens.auroraFill : Tokens.aurora
        case .manta:
            filled ? Tokens.mantaFill : Tokens.manta
        case .zkSync:
            filled ? Tokens.zksyncFill : Tokens.zksync
        case .moonbeam:
            filled ? Tokens.moonbeamFill : Tokens.moonbeam
        case .polygonZkEVM:
            filled ? Tokens.polygonzkevmFill : Tokens.polygonzkevm
        case .moonriver:
            filled ? Tokens.moonriverFill : Tokens.moonriver
        case .mantle:
            filled ? Tokens.mantleFill : Tokens.mantle
        case .flare:
            filled ? Tokens.flareFill : Tokens.flare
        case .taraxa:
            filled ? Tokens.taraxaFill : Tokens.taraxa
        case .radiant:
            filled ? Tokens.radiantFill : Tokens.radiant
        case .base:
            filled ? Tokens.baseFill : Tokens.base
        case .joystream:
            filled ? Tokens.joystreamFill : Tokens.joystream
        case .bittensor:
            filled ? Tokens.bittensorFill : Tokens.bittensor
        case .koinos:
            filled ? Tokens.koinosFill : Tokens.koinos
        case .internetComputer:
            filled ? Tokens.internetcomputerFill : Tokens.internetcomputer
        case .cyber:
            filled ? Tokens.cyberFill : Tokens.cyber
        case .blast:
            filled ? Tokens.blastFill : Tokens.blast
        case .sui:
            filled ? Tokens.suiFill : Tokens.sui
        case .filecoin:
            filled ? Tokens.filecoinFill : Tokens.filecoin
        case .sei:
            filled ? Tokens.seiFill : Tokens.sei
        case .energyWebEVM:
            filled ? Tokens.energywebevmFill : Tokens.energywebevm
        case .energyWebX:
            filled ? Tokens.energywebxFill : Tokens.energywebx
        case .core:
            filled ? Tokens.coreFill : Tokens.core
        case .canxium:
            filled ? Tokens.canxiumFill : Tokens.canxium
        case .casper:
            filled ? Tokens.casperFill : Tokens.casper
        case .chiliz:
            filled ? Tokens.chilizFill : Tokens.chiliz
        case .xodex:
            filled ? Tokens.xodexFill : Tokens.xodex
        case .clore:
            filled ? Tokens.cloreFill : Tokens.clore
        case .fact0rn:
            filled ? Tokens.fact0rnFill : Tokens.fact0rn
        case .odysseyChain:
            filled ? Tokens.odysseychainFill : Tokens.odysseychain
        case .bitrock:
            filled ? Tokens.bitrockFill : Tokens.bitrock
        case .apeChain:
            filled ? Tokens.apechainFill : Tokens.apechain
        case .sonic:
            filled ? Tokens.sonicFill : Tokens.sonic
        case .alephium:
            filled ? Tokens.alephiumFill : Tokens.alephium
        case .vanar:
            filled ? Tokens.vanarFill : Tokens.vanar
        case .zkLinkNova:
            filled ? Tokens.zklinknovaFill : Tokens.zklinknova
        }
    }
}

// MARK: - Blockchain ID

extension Set<Blockchain> {
    subscript(networkId: String) -> Blockchain? {
        // The "test" suffix no longer needed
        // since the coins are selected from the supported blockchains list
        // But we should remove it to support old application versions
        let testnetId = "/test"

        let clearNetworkId = networkId.replacingOccurrences(of: testnetId, with: "")
        if let blockchain = first(where: { $0.networkId == clearNetworkId }) {
            return blockchain
        }

        AppLogger.error(error: "⚠️⚠️⚠️ Blockchain with id: \(networkId) isn't contained in supported blockchains")
        return nil
    }
}
