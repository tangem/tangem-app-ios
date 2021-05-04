//
//  StellarSDKLog.swift
//  stellarsdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Soneso. All rights reserved.
//

import Foundation

public final class StellarSDKLog {

    
    public static func printHorizonRequestErrorMessage(tag: String, horizonRequestError: HorizonRequestError) {
        switch horizonRequestError {
        case .requestFailed(let message):
            print("\(tag): Horizon request error of type request failed with message: \(message)")
        case .badRequest(let message, let errorResponse):
            print("\(tag): Horizon request error of type request failed with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .unauthorized(let message):
            print("\(tag): Horizon request error of type request failed with message: \(message)")
        case .forbidden(let message, let errorResponse):
            print("\(tag): Horizon request error of type request failed with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .notFound(let message, let errorResponse):
            print("\(tag): Horizon request error of type request failed with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .notAcceptable(let message, let errorResponse):
            print("\(tag): Horizon request error of type request failed with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .beforeHistory(let message, let errorResponse):
            print("\(tag): Horizon request error of type request failed with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .rateLimitExceeded(let message, let errorResponse):
            print("\(tag): Horizon request error of type request failed with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .internalServerError(let message, let errorResponse):
            print("\(tag): Horizon request error of type request failed with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .notImplemented(let message, let errorResponse):
            print("\(tag): Horizon request error of type request failed with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .staleHistory(let message, let errorResponse):
            print("\(tag): Horizon request error of type request failed with message: \(message)")
            printErrorResponse(tag: tag, errorResponse: errorResponse)
        case .emptyResponse:
            print("\(tag): Horizon request error of type empty response.")
        case .parsingResponseFailed(let message):
            print("\(tag): Horizon request error of type request failed with message: \(message)")
        case .errorOnStreamReceive(let message):
            print("\(tag): Horizon request error of type request failed with message: \(message)")
        }
    }
    
    public static func printErrorResponse(tag: String, errorResponse: ErrorResponse?) {
        if (errorResponse == nil) {return}
        print("\(tag): Horizon Error response type: \(errorResponse!.type)")
        print("\(tag): Horizon Error response tite: \(errorResponse!.title)")
        print("\(tag): Horizon Error response httpStatusCode: \(errorResponse!.httpStatusCode)")
        print("\(tag): Horizon Error response detail: \(errorResponse!.detail)")
        print("\(tag): Horizon Error response instance: \(errorResponse!.instance ?? "unspecified")")
    }
}

