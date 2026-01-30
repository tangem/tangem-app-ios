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

@MainActor
protocol ReceiveAddressService: AnyObject {
    var addressTypes: [ReceiveAddressType] { get }
    var addressInfos: [ReceiveAddressInfo] { get }

    func update(with addresses: [Address]) async
}

// MARK: - CommonReceiveAddressService

@MainActor
final class CommonReceiveAddressService {
    // MARK: - Dependencies

    private let domainAddressResolver: DomainNameAddressResolver?
    private let receiveAddressInfoUtils: ReceiveAddressInfoUtils

    // MARK: - State

    private(set) var addressTypes: [ReceiveAddressType] = []
    private var resolveDomainTask: Task<Void, Never>?

    // MARK: - Init

    init(
        addresses: [Address],
        domainAddressResolver: DomainNameAddressResolver?,
        receiveAddressInfoUtils: ReceiveAddressInfoUtils = ReceiveAddressInfoUtils(colorScheme: .whiteBlack)
    ) {
        self.domainAddressResolver = domainAddressResolver
        self.receiveAddressInfoUtils = receiveAddressInfoUtils

        addressTypes = makeAddressTypes(from: addresses)
    }
}

// MARK: - ReceiveAddressService

extension CommonReceiveAddressService: ReceiveAddressService {
    var addressInfos: [ReceiveAddressInfo] {
        addressTypes.map(\.info)
    }

    func update(with addresses: [Address]) async {
        resolveDomainTask?.cancel()
        addressTypes = makeAddressTypes(from: addresses)

        await resolveDomainNamesIfNeeded()
    }
}

// MARK: - Private

private extension CommonReceiveAddressService {
    func makeAddressTypes(from addresses: [Address]) -> [ReceiveAddressType] {
        receiveAddressInfoUtils
            .makeAddressInfos(from: addresses)
            .map { .address($0) }
    }

    func resolveDomainNamesIfNeeded() async {
        guard domainAddressResolver != nil else {
            return
        }

        resolveDomainTask = Task { [weak self] in
            await self?.resolveDomainNames()
        }

        await resolveDomainTask?.value
    }

    func resolveDomainNames() async {
        guard let domainAddressResolver else {
            return
        }

        for addressInfo in addressInfos {
            guard !Task.isCancelled else {
                return
            }

            do {
                let domainName = try await domainAddressResolver.resolveDomainName(addressInfo.address)
                addressTypes.append(.domain(domainName, addressInfo))
            } catch is CancellationError {
                return
            } catch {
                // Domain name not found for this address — expected for most addresses
            }
        }
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
