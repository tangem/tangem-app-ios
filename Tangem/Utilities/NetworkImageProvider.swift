//
//  NetworkImageProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemAssets
import TangemNFT

struct NetworkImageProvider: NFTChainIconProvider {
    func provide(by blockchain: Blockchain, filled: Bool) -> ImageType {
        switch blockchain {
        case .bitcoin:
            filled ? Tokens.bitcoinFill : Tokens.bitcoin
        case .litecoin:
            filled ? Tokens.litecoinFill : Tokens.litecoin
        case .stellar:
            filled ? Tokens.stellarFill : Tokens.stellar
        case .ethereum:
            ethereum(filled: filled)
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
            bsc(filled: filled)
        case .polygon:
            filled ? Tokens.polygonFill : Tokens.polygon
        case .avalanche:
            avalanche(filled: filled)
        case .solana:
            solana(filled: filled)
        case .fantom:
            fantom(filled: filled)
        case .polkadot:
            filled ? Tokens.polkadotFill : Tokens.polkadot
        case .kusama:
            filled ? Tokens.kusamaFill : Tokens.kusama
        case .azero:
            filled ? Tokens.azeroFill : Tokens.azero
        case .tron:
            filled ? Tokens.tronFill : Tokens.tron
        case .arbitrum:
            arbitrum(filled: filled)
        case .dash:
            filled ? Tokens.dashFill : Tokens.dash
        case .gnosis:
            gnosis(filled: filled)
        case .optimism:
            optimism(filled: filled)
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
            cronos(filled: filled)
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
            moonbeam(filled: filled)
        case .polygonZkEVM:
            filled ? Tokens.polygonzkevmFill : Tokens.polygonzkevm
        case .moonriver:
            moonriver(filled: filled)
        case .mantle:
            filled ? Tokens.mantleFill : Tokens.mantle
        case .flare:
            filled ? Tokens.flareFill : Tokens.flare
        case .taraxa:
            filled ? Tokens.taraxaFill : Tokens.taraxa
        case .radiant:
            filled ? Tokens.radiantFill : Tokens.radiant
        case .base:
            base(filled: filled)
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
            chiliz(filled: filled)
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
        case .pepecoin:
            filled ? Tokens.pepecoinFill : Tokens.pepecoin
        case .hyperliquidEVM:
            filled ? Tokens.hyperliquidFill : Tokens.hyperliquid
        case .quai:
            filled ? Tokens.quaiFill : Tokens.quai
        case .scroll:
            filled ? Tokens.scrollFill : Tokens.scroll
        case .linea:
            filled ? Tokens.lineaFill : Tokens.linea
        case .monad:
            filled ? Tokens.monadFill : Tokens.monad
        case .berachain:
            filled ? Tokens.berachainFill : Tokens.berachain
        case .arbitrumNova:
            filled ? Tokens.arbitrumnovaFill : Tokens.arbitrumnova
        case .plasma:
            filled ? Tokens.plasmaFill : Tokens.plasma
        }
    }

    func provide(by nftChain: NFTChain) -> ImageType {
        switch nftChain {
        case .ethereum:
            ethereum()
        case .polygon:
            polygon()
        case .bsc:
            bsc()
        case .avalanche:
            avalanche()
        case .fantom:
            fantom()
        case .cronos:
            cronos()
        case .arbitrum:
            arbitrum()
        case .gnosis:
            gnosis()
        case .chiliz:
            chiliz()
        case .base:
            base()
        case .optimism:
            optimism()
        case .moonbeam:
            moonbeam()
        case .moonriver:
            moonriver()
        case .solana:
            solana()
        }
    }

    private func ethereum(filled: Bool = true) -> ImageType {
        filled ? Tokens.ethereumFill : Tokens.ethereum
    }

    private func polygon(filled: Bool = true) -> ImageType {
        filled ? Tokens.polygonFill : Tokens.polygon
    }

    private func bsc(filled: Bool = true) -> ImageType {
        filled ? Tokens.bscFill : Tokens.bsc
    }

    private func avalanche(filled: Bool = true) -> ImageType {
        filled ? Tokens.avalancheFill : Tokens.avalanche
    }

    private func cronos(filled: Bool = true) -> ImageType {
        filled ? Tokens.cronosFill : Tokens.cronos
    }

    private func fantom(filled: Bool = true) -> ImageType {
        filled ? Tokens.fantomFill : Tokens.fantom
    }

    private func arbitrum(filled: Bool = true) -> ImageType {
        filled ? Tokens.arbitrumFill : Tokens.arbitrum
    }

    private func gnosis(filled: Bool = true) -> ImageType {
        filled ? Tokens.gnosisFill : Tokens.gnosis
    }

    private func chiliz(filled: Bool = true) -> ImageType {
        filled ? Tokens.chilizFill : Tokens.chiliz
    }

    private func base(filled: Bool = true) -> ImageType {
        filled ? Tokens.baseFill : Tokens.base
    }

    private func optimism(filled: Bool = true) -> ImageType {
        filled ? Tokens.optimismFill : Tokens.optimism
    }

    private func moonbeam(filled: Bool = true) -> ImageType {
        filled ? Tokens.moonbeamFill : Tokens.moonbeam
    }

    private func moonriver(filled: Bool = true) -> ImageType {
        filled ? Tokens.moonriverFill : Tokens.moonriver
    }

    private func solana(filled: Bool = true) -> ImageType {
        filled ? Tokens.solanaFill : Tokens.solana
    }
}
