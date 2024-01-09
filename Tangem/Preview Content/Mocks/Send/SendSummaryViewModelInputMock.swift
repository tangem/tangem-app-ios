////
////  SendSummaryViewModelInputMock.swift
////  Tangem
////
////  Created by [REDACTED_AUTHOR]
////  Copyright © 2023 Tangem AG. All rights reserved.
////
//
// import SwiftUI
// import Combine
//
// class SendSummaryViewModelInputMock: SendSummaryViewModelInput {
//    var destination2: AnyPublisher<String, Never> { .just(output: "") }
//    var additionalField2: AnyPublisher<(SendAdditionalFields, String)?, Never> { .just(output: (SendAdditionalFields.memo, "")) }
//
//    var amountText: String { "100,00" }
//    var canEditAmount: Bool { true }
//    var canEditDestination: Bool { true }
//    var destinationTextBinding: Binding<String> { .constant("0x0123123") }
//    var feeTextPublisher: AnyPublisher<String?, Never> { .just(output: "0.1 ETH") }
//    var isSending: AnyPublisher<Bool, Never> { .just(output: false) }
//
//    func send() {}
// }
