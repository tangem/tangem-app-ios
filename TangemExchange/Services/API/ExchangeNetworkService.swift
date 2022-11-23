//
//  NetworkFacade.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Moya

class NetworkService {
    let isDebug: Bool

    // MARK: - Private variable

    private var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    private let provider = MoyaProvider<BaseTarget>()

    init(isDebug: Bool) {
        self.isDebug = isDebug
    }

    // MARK: - Internal methods

    func request<T: Decodable>(with target: BaseTarget) async -> Result<T, ExchangeInchError> {
        let asyncRequestWrapper = AsyncMoyaRequestWrapper<T> { [weak self] continuation in
            guard let self = self else { return nil }

            return self.provider.request(target) { result in
                switch result {
                case .success(let response):
                    if self.isDebug {
                        print("URL REQUEST -> \(response.request?.url?.absoluteString ?? "")")
                    }

                    if let response = try? response.filterSuccessfulStatusCodes() {
                        self.logIfNeeded(data: response.data)

                        do {
                            let object = try self.jsonDecoder.decode(T.self, from: response.data)
                            continuation.resume(returning: .success(object))
                        } catch {
                            continuation.resume(returning: .failure(.decodeError(error: error)))
                        }
                    } else {
                        do {
                            let errorObject = try self.jsonDecoder.decode(InchError.self, from: response.data)
                            self.logIfNeeded(data: response.data)
                            continuation.resume(returning: .failure(.parsedError(withInfo: errorObject)))
                        } catch {
                            if self.isDebug {
                                print("Error -> \(error.localizedDescription)")
                            }
                            continuation.resume(returning: .failure(.unknownError(statusCode: response.statusCode)))
                        }
                    }
                case .failure(let error):
                    if self.isDebug {
                        print("Error -> \(error.localizedDescription)")
                    }
                    continuation.resume(returning: .failure(.serverError(withError: error)))
                }
            }
        }

        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                asyncRequestWrapper.perform(continuation: continuation)
            }
        } onCancel: {
            asyncRequestWrapper.cancel()
        }
    }

    // MARK: - Private

    private func logIfNeeded(data: Data) {
        if isDebug {
            do {
                let decodeJSON = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                let dataJSON = try JSONSerialization.data(withJSONObject: decodeJSON, options: .prettyPrinted)
                print(String(decoding: dataJSON, as: UTF8.self))
            } catch {
                print("Decoding response error -> \(error)")
            }
        }
    }
}
