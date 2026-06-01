//
//  UTXONetworkParamsDustCalculator+Networks.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

extension UTXONetworkParamsDustCalculator where Self == BitcoinUTXONetworkParamsDustCalculator {
    /// https://github.com/bitcoin/bitcoin/blob/master/src/policy/policy.h#L52
    static var bitcoinMainnet: Self { .init(dustRelayTxFee: 3000) }

    /// https://github.com/bitcoin/bitcoin/blob/master/src/policy/policy.h#L52
    static var bitcoinTestnet: Self { .init(dustRelayTxFee: 3000) }

    /// https://github.com/Bitcoin-ABC/bitcoin-abc/blob/master/src/policy/policy.h#L78
    static var bitcoinCashMainnet: Self { .init(dustRelayTxFee: 3000) }

    /// https://github.com/Bitcoin-ABC/bitcoin-abc/blob/master/src/policy/policy.h#L78
    static var bitcoinCashTestnet: Self { .init(dustRelayTxFee: 1000) }

    /// https://github.com/bitcoin/bitcoin/blob/master/src/policy/policy.h#L52
    static var litecoin: Self { .init(dustRelayTxFee: 3000) }

    /// https://github.com/dashpay/dash/blob/master/src/policy/policy.h#L38
    static var dashMainnet: Self { .init(dustRelayTxFee: 3000) }

    /// https://github.com/dashpay/dash/blob/master/src/policy/policy.h#L36
    static var dashTestnet: Self { .init(dustRelayTxFee: 1000) }

    /// https://github.com/RavenProject/Ravencoin/blob/master/src/policy/policy.h#L48
    /// `static const unsigned int DUST_RELAY_TX_FEE = 3000;`
    static var ravencoinMainnet: Self { .init(dustRelayTxFee: 3000) }

    /// https://github.com/RavenProject/Ravencoin/blob/master/src/policy/policy.h#L48
    /// `static const unsigned int DUST_RELAY_TX_FEE = 3000;`
    static var ravencoinTestnet: Self { .init(dustRelayTxFee: 3000) }

    /// Radiant is a Bitcoin Cash fork; uses the standard `DUST_RELAY_TX_FEE`.
    static var radiant: Self { .init(dustRelayTxFee: 3000) }

    /// https://github.com/FACT0RN/FACT0RN/blob/d02b33f3d5ce8a4be57fdb8c8b0bc3cb51760116/src/policy/policy.h#L54
    static var fact0rn: Self { .init(dustRelayTxFee: 3000) }

    /// https://github.com/bitcoin/bitcoin/blob/master/src/policy/policy.h#L52
    static var ducatus: Self { .init(dustRelayTxFee: 3000) }
}

extension UTXONetworkParamsDustCalculator where Self == DogecoinUTXONetworkParamsDustCalculator {
    static var dogecoin: Self { .init() }
}

extension UTXONetworkParamsDustCalculator where Self == PepecoinUTXONetworkParamsDustCalculator {
    static var pepecoin: Self { .init() }
}

extension UTXONetworkParamsDustCalculator where Self == KaspaUTXONetworkParamsDustCalculator {
    static var kaspa: Self { .init() }
}
