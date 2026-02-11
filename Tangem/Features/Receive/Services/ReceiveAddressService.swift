//
//  ReceiveAddressService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation

protocol ReceiveAddressService: AnyObject {
    var addressTypes: [ReceiveAddressType] { get }
    var addressInfos: [ReceiveAddressInfo] { get }

    func update(with addresses: [Address]) async
}

// MARK: - CommonReceiveAddressService

final class CommonReceiveAddressService {
    // MARK: - Dependencies

    private let domainAddressResolver: DomainNameAddressResolver?
    private let receiveAddressInfoUtils: ReceiveAddressInfoUtils

    // MARK: - State

    private var _addressTypes: [ReceiveAddressType] = []

    // MARK: - Init

    init(
        addresses: [Address],
        domainAddressResolver: DomainNameAddressResolver?,
        receiveAddressInfoUtils: ReceiveAddressInfoUtils = ReceiveAddressInfoUtils(colorScheme: .whiteBlack)
    ) {
        self.domainAddressResolver = domainAddressResolver
        self.receiveAddressInfoUtils = receiveAddressInfoUtils
        _addressTypes = makeAddressTypes(from: addresses)
    }
}

// MARK: - ReceiveAddressService

extension CommonReceiveAddressService: ReceiveAddressService {
    var addressTypes: [ReceiveAddressType] {
        ensureOnMainQueue()

        return _addressTypes
    }

    var addressInfos: [ReceiveAddressInfo] {
        ensureOnMainQueue()

        return _addressTypes.map(\.info)
    }

    func update(with addresses: [Address]) async {
        let addressInfos = receiveAddressInfoUtils.makeAddressInfos(from: addresses)
        var resultTypes: [ReceiveAddressType] = addressInfos.map { .address($0) }

        if let domainAddressResolver {
            let domainTypes = await resolveDomainNames(for: addressInfos, using: domainAddressResolver)
            resultTypes.append(contentsOf: domainTypes)
        }

        await setAddressTypes(resultTypes)
    }

    @MainActor
    private func setAddressTypes(_ types: [ReceiveAddressType]) {
        _addressTypes = types
    }
}

// MARK: - Private

private extension CommonReceiveAddressService {
    func makeAddressTypes(from addresses: [Address]) -> [ReceiveAddressType] {
        receiveAddressInfoUtils
            .makeAddressInfos(from: addresses)
            .map { .address($0) }
    }

    func resolveDomainNames(
        for addressInfos: [ReceiveAddressInfo],
        using resolver: DomainNameAddressResolver
    ) async -> [ReceiveAddressType] {
        var domainTypes: [ReceiveAddressType] = []
        do {
            for addressInfo in addressInfos {
                try Task.checkCancellation()
                let domainName = try await resolver.resolveDomainName(addressInfo.address)
                domainTypes.append(.domain(domainName, addressInfo))
            }
        } catch is CancellationError {
            return []
        } catch {
            // Fall-through
        }
        return domainTypes
    }
}

// MARK: - Dummy

class DummyReceiveAddressService: ReceiveAddressService {
    private let receiveAddressInfoUtils = ReceiveAddressInfoUtils(colorScheme: .whiteBlack)

    var addressTypes: [ReceiveAddressType] {
        _addressInfos.map { .address($0) }
    }

    var addressInfos: [ReceiveAddressInfo] {
        _addressInfos
    }

    func update(with addresses: [Address]) async {
        _addressInfos = receiveAddressInfoUtils.makeAddressInfos(from: addresses)
    }

    // MARK: - Private Properties

    private var _addressInfos: [ReceiveAddressInfo]

    // MARK: - Init

    init(addressInfos: [ReceiveAddressInfo]) {
        _addressInfos = addressInfos
    }
}
