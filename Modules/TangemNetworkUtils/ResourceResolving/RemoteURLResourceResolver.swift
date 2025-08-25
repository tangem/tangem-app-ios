//
//  RemoteURLResourceResolver.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import struct UniformTypeIdentifiers.UTType

/// A service that inspects a remote ``URL`` and resolves its content type, optionally downloading the full data.
///
/// The service attempts to minimize bandwidth usage by performing a `Range` request to fetch only the initial bytes of the resource.
/// If the server does not support partial content requests, it falls back to downloading the full resource.
public final class RemoteURLResourceResolver {
    private static let validStatusCodeRange = 200 ... 299
    private static let partialContentStatusCode = 206

    private let session: URLSession

    public init(session: URLSession) {
        self.session = session
    }

    /// Resolves the MIME type of a resource at the given URL, and optionally includes its data.
    /// - Parameter url: the remote ``URL`` to inspect.
    /// - Returns: a ``ResolvedResource`` containing the content type and optional data.
    /// - Throws: a ``RemoteURLResourceResolver.Error`` if the request fails / cancelled or the response is not valid.
    public func resolve(url: URL) async throws(Error) -> ResolvedResource {
        let (data, httpResponse) = try await performRequest(with: url)

        try Self.validate(httpResponse: httpResponse)
        let universalType = try Self.parseUniversalType(from: httpResponse)

        let resourceData = httpResponse.statusCode == Self.partialContentStatusCode
            ? nil
            : data

        return ResolvedResource(url: url, universalType: universalType, data: resourceData)
    }

    private func performRequest(with url: URL) async throws(Error) -> (Data, HTTPURLResponse) {
        guard !Task.isCancelled else {
            throw Error.cancelled
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: Self.makeRequest(for: url))
        } catch is CancellationError {
            throw Error.cancelled
        } catch {
            throw Error.requestFailed(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw Error.unsupportedResponseType(response)
        }

        return (data, httpResponse)
    }

    private static func makeRequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("bytes=0-1", forHTTPHeaderField: "Range")
        return request
    }

    private static func validate(httpResponse: HTTPURLResponse) throws(Error) {
        guard validStatusCodeRange.contains(httpResponse.statusCode) else {
            throw Error.badStatusCode(httpResponse.statusCode)
        }
    }

    private static func parseUniversalType(from httpResponse: HTTPURLResponse) throws(Error) -> UTType {
        guard let mimeType = httpResponse.mimeType else {
            throw Error.mimeTypeMissing
        }

        guard let universalType = UTType(mimeType: mimeType) else {
            throw Error.unsupportedMimeType(mimeType)
        }

        return universalType
    }
}

public extension RemoteURLResourceResolver {
    enum Error: Swift.Error {
        case cancelled
        case requestFailed(any Swift.Error)
        case unsupportedResponseType(URLResponse)
        case badStatusCode(Int)
        case mimeTypeMissing
        case unsupportedMimeType(String)
    }
}
