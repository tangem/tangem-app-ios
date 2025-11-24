//
//  HostAnalyticsFormatterUtilTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemFoundation
@testable import Tangem

final class HostAnalyticsFormatterUtilTests: XCTestCase {
    private var sut: HostAnalyticsFormatterUtil!

    override func setUp() {
        super.setUp()
        sut = HostAnalyticsFormatterUtil()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - URL Formatting Tests

    func testFormatSimpleHTTPSURL() {
        // Given
        let input = "https://api.example.com"

        // When
        let result = sut.formattedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_api_example_com")
    }

    func testFormatHTTPURL() {
        // Given
        let input = "http://api.example.com"

        // When
        let result = sut.formattedHost(from: input)

        // Then
        XCTAssertEqual(result, "http_api_example_com")
    }

    func testFormatURLWithPort() {
        // Given
        let input = "https://api.example.com:8080"

        // When
        let result = sut.formattedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_api_example_com_8080")
    }

    func testFormatURLWithPathComponents() {
        // Given
        let input = "https://api.example.com/v1/users"

        // When
        let result = sut.formattedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_api_example_com_v1_users")
    }

    func testFormatURLWithLongPathComponent() {
        // Given
        let input = "https://api.example.com/v1/abcdef1234567890KEYSECRET123456"

        // When
        let result = sut.formattedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_api_example_com_v1_abcdef1234567890keysecret123456")
    }

    func testFormatURLWithMultiplePathComponents() {
        // Given
        let input = "https://api.example.com/v1/endpoint/abc123def456ghi789jkl012"

        // When
        let result = sut.formattedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_api_example_com_v1_endpoint_abc123def456ghi789jkl012")
    }

    func testFormatURLWithPortAndPath() {
        // Given
        let input = "https://api.example.com:9000/v1/data"

        // When
        let result = sut.formattedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_api_example_com_9000_v1_data")
    }

    // MARK: - Hostname Formatting Tests

    func testFormatSimpleHostname() {
        // Given
        let input = "api.example.com"

        // When
        let result = sut.formattedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_api_example_com")
    }

    func testFormatHostnameWithSubdomains() {
        // Given
        let input = "sub.api.example.com"

        // When
        let result = sut.formattedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_sub_api_example_com")
    }

    func testFormatHostnameWithoutDots() {
        // Given
        let input = "localhost"

        // When
        let result = sut.formattedHost(from: input)

        // Then
        XCTAssertEqual(result, "localhost")
    }

    func testFormatHostnameAlreadyWithHTTPPrefix() {
        // Given
        let input = "http_api_example_com"

        // When
        let result = sut.formattedHost(from: input)

        // Then
        XCTAssertEqual(result, "http_api_example_com")
    }

    // MARK: - Case Sensitivity Tests

    func testFormatURLWithUppercaseCharacters() {
        // Given
        let input = "HTTPS://API.EXAMPLE.COM/V1/Users"

        // When
        let result = sut.formattedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_api_example_com_v1_users")
    }

    func testFormatHostnameWithUppercaseCharacters() {
        // Given
        let input = "API.EXAMPLE.COM"

        // When
        let result = sut.formattedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_api_example_com")
    }

    // MARK: - Path Component Tests

    func testFormatURLWithDashesAndUnderscoresInPath() {
        // Given
        let input = "https://api.example.com/abc-def_ghi-123456789"

        // When
        let result = sut.formattedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_api_example_com_abc-def_ghi-123456789")
    }

    func testFormatURLWithSpecialCharactersInPath() {
        // Given
        let input = "https://api.example.com/abcdef@1234567890123"

        // When
        let result = sut.formattedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_api_example_com_abcdef@1234567890123")
    }

    func testFormatURLWithMultipleSlashes() {
        // Given
        let input = "https://api.example.com/abc/def/ghi/jkl/mno/pqr"

        // When
        let result = sut.formattedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_api_example_com_abc_def_ghi_jkl_mno_pqr")
    }

    // MARK: - Edge Cases

    func testFormatEmptyString() {
        // Given
        let input = ""

        // When
        let result = sut.formattedHost(from: input)

        // Then
        XCTAssertEqual(result, "")
    }

    func testFormatURLWithOnlyScheme() {
        // Given
        let input = "https://"

        // When
        let result = sut.formattedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_")
    }

    func testFormatIPAddress() {
        // Given
        let input = "192.168.1.1"

        // When
        let result = sut.formattedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_192_168_1_1")
    }

    func testFormatIPAddressWithScheme() {
        // Given
        let input = "http://192.168.1.1:8080"

        // When
        let result = sut.formattedHost(from: input)

        // Then
        XCTAssertEqual(result, "http_192_168_1_1_8080")
    }

    func testFormatURLWithTrailingSlash() {
        // Given
        let input = "https://api.example.com/"

        // When
        let result = sut.formattedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_api_example_com")
    }

    func testFormatComplexRealWorldURL() {
        // Given
        let input = "https://mainnet.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161"

        // When
        let result = sut.formattedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_mainnet_infura_io_v3_9aa3d95b3bc440fa88ea12eaa4456161")
    }

    func testFormatURLWithQueryParameters() {
        // Given
        let input = "https://api.example.com/v1/data?key=abcd1234efgh5678ijkl"

        // When
        let result = sut.formattedHost(from: input)

        // Then
        // Note: URL parsing treats query parameters separately from path
        XCTAssertEqual(result, "https_api_example_com_v1_data")
    }

    // MARK: - Additional Analytics Use Cases

    func testFormatURLWithVersionedAPI() {
        // Given
        let input = "https://api.tangem.com/v2/blockchain/ethereum"

        // When
        let result = sut.formattedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_api_tangem_com_v2_blockchain_ethereum")
    }

    func testFormatURLWithSubdomainAndPort() {
        // Given
        let input = "https://rpc.mainnet.example.com:443/api/v1"

        // When
        let result = sut.formattedHost(from: input)

        // Then
        XCTAssertEqual(result, "https_rpc_mainnet_example_com_443_api_v1")
    }

    func testFormatLocalDevelopmentURL() {
        // Given
        let input = "http://localhost:3000/api/test"

        // When
        let result = sut.formattedHost(from: input)

        // Then
        XCTAssertEqual(result, "http_localhost_3000_api_test")
    }

    // MARK: - Real Provider URLs from providers_order.json

    func testFormatAllPublicProviderURLs() {
        // Given - All public URLs from providers_order.json
        let publicURLs = [
            // aleph-zero
            "https://rpc.azero.dev/",
            "https://aleph-zero.api.onfinality.io/public/",
            // alephium
            "https://node.mainnet.alephium.org/",
            // algorand
            "https://mainnet-api.algonode.cloud/",
            // aptos
            "https://fullnode.mainnet.aptoslabs.com/",
            // arbitrum-one
            "https://arb1.arbitrum.io/rpc/",
            "https://1rpc.io/arb/",
            "https://arbitrum-one-rpc.publicnode.com/",
            "https://rpc.ankr.com/arbitrum/",
            "https://arbitrum-one.public.blastapi.io/",
            // areon-network
            "https://mainnet-rpc.areon.network/",
            "https://mainnet-rpc2.areon.network/",
            "https://mainnet-rpc3.areon.network/",
            "https://mainnet-rpc4.areon.network/",
            "https://mainnet-rpc5.areon.network/",
            // aurora
            "https://mainnet.aurora.dev/",
            "https://aurora.drpc.org/",
            "https://1rpc.io/aurora/",
            // avalanche
            "https://api.avax.network/ext/bc/C/rpc/",
            // base
            "https://mainnet.base.org/",
            "https://base.meowrpc.com/",
            "https://base-rpc.publicnode.com/",
            "https://base.llamarpc.com/",
            // binance-smart-chain
            "https://bsc-dataseed.binance.org/",
            // bittensor
            "https://entrypoint-finney.opentensor.ai/",
            // blast
            "https://rpc.blast.io/",
            "https://blast-rpc.publicnode.com/",
            "https://rpc.ankr.com/blast/",
            // canxium
            "https://rpc.canxium.org/",
            "https://canxium.rpc.thirdweb.com/",
            // casper-network
            "https://node.mainnet.casper.network/rpc/",
            // chiliz
            "https://rpc.chiliz.com/",
            "https://rpc.ankr.com/chiliz/",
            "https://chiliz.publicnode.com/",
            // core
            "https://rpc.ankr.com/core/",
            "https://rpc.coredao.org/",
            "https://core.public.infstones.com/",
            // cosmos
            "https://rest.cosmos.directory/cosmoshub/",
            "https://rest-cosmoshub.ecostake.com/",
            // cronos
            "https://evm.cronos.org/",
            "https://evm-cronos.crypto.org/",
            // cyber
            "https://rpc.cyber.co/",
            "https://cyber.alt.technology/",
            // decimal
            "https://node.decimalchain.com/web3/",
            "https://node1-mainnet.decimalchain.com/web3/",
            "https://node2-mainnet.decimalchain.com/web3/",
            "https://node3-mainnet.decimalchain.com/web3/",
            "https://node4-mainnet.decimalchain.com/web3/",
            // energy-web-chain
            "https://rpc.energyweb.org/",
            "https://consortia-rpc.energyweb.org/",
            "https://energy-web-chain.rpc.thirdweb.com/",
            "https://explorer.energyweb.org/api/",
            // energy-web-x
            "https://public-rpc.mainnet.energywebx.com/",
            "https://wnp-rpc.mainnet.energywebx.com/",
            // ethereum-classic
            "https://etc.etcdesktop.com/",
            "https://etc.mytokenpocket.vip/",
            "https://geth-at.etc-network.info/",
            // ethereumfair
            "https://rpc.dischain.xyz/",
            // ethereum-pow-iou
            "https://mainnet.ethereumpow.org/",
            // fact0rn
            "wss://electrumx.fact0rn.io:443/",
            "wss://electrumx2.fact0rn.io:443/",
            "wss://electrumx3.fact0rn.io:443/",
            // fantom
            "https://rpcapi.fantom.network/",
            "https://fantom-mainnet.public.blastapi.io/",
            "https://rpc.ankr.com/fantom/",
            // filecoin
            "https://rpc.ankr.com/filecoin/",
            "https://filecoin.chainup.net/rpc/v1/",
            // flare-network
            "https://flare-api.flare.network/ext/bc/C/rpc/",
            "https://flare.rpc.thirdweb.com/",
            "https://rpc.ankr.com/flare/",
            "https://flare.solidifi.app/ext/C/rpc/",
            // hedera-hashgraph
            "https://mainnet-public.mirrornode.hedera.com/api/v1/",
            // hyperevm
            "https://rpc.hyperliquid.xyz/evm/",
            "https://rpc.hypurrscan.io/",
            // internet-computer
            "https://icp-api.io/",
            // joystream
            "https://rpc.joyutils.org/",
            "https://rpc.joystream.org/",
            // kaspa
            "https://api.kaspa.org/",
            // kava
            "https://evm.kava.io/",
            "https://evm2.kava.io/",
            // koinos
            "https://api.koinos.io/",
            "https://api.koinosblocks.com/",
            // kusama
            "https://asset-hub-kusama-rpc.n.dwellir.com/",
            "https://statemine-rpc-tn.dwellir.com/",
            "https://sys.ibp.network/asset-hub-kusama/",
            "https://asset-hub-kusama.dotters.network/",
            "https://rpc-asset-hub-kusama.luckyfriday.io/",
            "https://assethub-kusama.api.onfinality.io/public/",
            "https://kusama-asset-hub-rpc.polkadot.io/",
            "https://ksm-rpc.stakeworld.io/assethub/",
            // manta-pacific
            "https://manta-pacific.drpc.org/",
            "https://pacific-rpc.manta.network/http/",
            "https://1rpc.io/manta/",
            // mantle
            "https://rpc.mantle.xyz/",
            "https://mantle-rpc.publicnode.com/",
            "https://mantle-mainnet.public.blastapi.io/",
            "https://1rpc.io/mantle/",
            // moonbeam
            "https://rpc.api.moonbeam.network/",
            "https://1rpc.io/glmr/",
            "https://moonbeam.public.blastapi.io/",
            "https://moonbeam-rpc.dwellir.com/",
            "https://moonbeam.unitedbloc.com/",
            "https://moonbeam-rpc.publicnode.com/",
            "https://rpc.ankr.com/moonbeam/",
            // moonriver
            "https://moonriver-rpc.dwellir.com/",
            "https://moonriver.unitedbloc.com/",
            "https://moonriver-rpc.publicnode.com/",
            // near-protocol
            "https://rpc.mainnet.near.org/",
            // octaspace
            "https://rpc.octa.space/",
            "https://octaspace.rpc.thirdweb.com/",
            // optimistic-ethereum
            "https://mainnet.optimism.io/",
            "https://optimism-mainnet.public.blastapi.io/",
            // playa3ull-games
            "https://api.mainnet.playa3ull.games/",
            // polkadot
            "https://rpc.polkadot.io/",
            "https://polkadot.api.onfinality.io/public-ws/",
            "https://polkadot-rpc.dwellir.com/",
            // polygon-pos
            "https://polygon-rpc.com/",
            "https://rpc-mainnet.matic.quiknode.pro/",
            // polygon-zkevm
            "https://zkevm-rpc.com/",
            "https://1rpc.io/polygon/zkevm/",
            "https://polygon-zkevm.drpc.org/",
            "https://polygon-zkevm-mainnet.public.blastapi.io/",
            // pulsechain
            "https://rpc.pulsechain.com/",
            "https://rpc-pulsechain.g4mm4.io/",
            // radiant
            "wss://electrumx.radiant4people.com:50022/",
            "wss://electrumx2.radiant4people.com:50022/",
            "wss://electrumx-dex02.radiantexplorer.com:50022/",
            "wss://electrumx-01-ssl.radiant4people.com:51002/",
            "wss://electrumx-02-ssl.radiant4people.com:51002/",
            // ravencoin
            "https://explorer.rvn.zelcore.io/api/",
            // rootstock
            "https://public-node.rsk.co/",
            // sei-network
            "https://rest.wallet.pacific-1.sei.io/",
            "https://rest.sei-apis.com/",
            "https://sei-api.polkachu.com/",
            "https://sei-rest.brocha.in/",
            // shibarium
            "https://www.shibrpc.com/",
            // stellar
            "https://horizon.stellar.org/",
            // taraxa
            "https://rpc.mainnet.taraxa.io/",
            // telos
            "https://mainnet.telos.net/evm/",
            "https://telos-evm.rpc.thirdweb.com/",
            // terra
            "https://terra-classic-lcd.publicnode.com/",
            // terra-2
            "https://phoenix-lcd.terra.dev/",
            // tezos
            "https://rpc.tzbeta.net/",
            "https://mainnet.smartpy.io/",
            // the-open-network
            // tron
            "https://api.trongrid.io/",
            // vechain
            "https://mainnet.vecha.in/",
            "https://sync-mainnet.vechain.org/",
            "https://mainnet.veblocks.net/",
            "https://mainnetc1.vechain.network/",
            "https://us.node.vechain.energy/",
            // xdai
            "https://rpc.gnosischain.com/",
            "https://gnosis-mainnet.public.blastapi.io/",
            "https://rpc.ankr.com/gnosis/",
            // xdc-network
            "https://rpc.xdcrpc.com/",
            "https://erpc.xdcrpc.com/",
            "https://rpc.xinfin.network/",
            "https://erpc.xinfin.network/",
            "https://rpc.ankr.com/xdc/",
            "https://rpc1.xinfin.network/",
            // xodex
            "https://mainnet.xo-dex.com/rpc/",
            "https://2415.rpc.thirdweb.com/",
            // xrp
            "https://xrplcluster.com/",
            // zksync
            "https://mainnet.era.zksync.io/",
            "https://1rpc.io/zksync2-era/",
            "https://zksync.meowrpc.com/",
            // sui
            "https://fullnode.mainnet.sui.io/",
            "https://rpc-mainnet.suiscan.xyz/",
            // clore-ai
            "https://blockbook.clore.ai/",
            "https://blockbook.clore.zelcore.io/",
            // dione
            "https://node.dioneprotocol.com/ext/bc/D/rpc/",
            // bitrock
            "https://connect.bit-rock.io/",
            "https://brockrpc.io/",
            // sonic
            "https://rpc.soniclabs.com/",
            "https://sonic-rpc.publicnode.com/",
            // apechain
            "https://rpc.apechain.com/",
            "https://apechain.drpc.org/",
            "https://apechain.calderachain.xyz/http/",
            // vanar-chain
            "https://rpc.vanarchain.com/",
            // zklink
            "https://rpc.zklink.io/",
            "https://rpc.zklink.network/",
            // pepecoin
            "wss://electrum.pepeblocks.com:50004/",
            "wss://electrum.pepelum.site:50004/",
            "wss://electrum.pepe.tips:50004/",
            // quai-network
            "https://rpc.quai.network/cyprus1/",
            "https://9.rpc.thirdweb.com/",
            // scroll
            "https://rpc.scroll.io/",
            "https://scroll-rpc.publicnode.com/",
            "https://scroll-mainnet.public.blastapi.io/",
            // linea
            "https://rpc.linea.build/",
            "https://linea-rpc.publicnode.com/",
            // plasma
            "https://rpc.plasma.to/",
            "https://plasma.drpc.org/",
        ]

        // When/Then
        for url in publicURLs {
            let result = sut.formattedHost(from: url)

            // Verify result is not empty
            XCTAssertFalse(result.isEmpty, "Formatted host should not be empty for URL: \(url)")

            // Verify result is lowercased
            XCTAssertEqual(result, result.lowercased(), "Formatted host should be lowercased for URL: \(url)")

            // Print for debugging
            print("✓ \(url) -> \(result)")
        }

        print("\n✅ Successfully formatted \(publicURLs.count) public provider URLs")
    }
}
