// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: core/contract/exchange_contract.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

import Foundation
import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

struct Protocol_ExchangeCreateContract: @unchecked Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var ownerAddress: Data = Data()

  var firstTokenID: Data = Data()

  var firstTokenBalance: Int64 = 0

  var secondTokenID: Data = Data()

  var secondTokenBalance: Int64 = 0

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

struct Protocol_ExchangeInjectContract: @unchecked Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var ownerAddress: Data = Data()

  var exchangeID: Int64 = 0

  var tokenID: Data = Data()

  var quant: Int64 = 0

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

struct Protocol_ExchangeWithdrawContract: @unchecked Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var ownerAddress: Data = Data()

  var exchangeID: Int64 = 0

  var tokenID: Data = Data()

  var quant: Int64 = 0

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

struct Protocol_ExchangeTransactionContract: @unchecked Sendable {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var ownerAddress: Data = Data()

  var exchangeID: Int64 = 0

  var tokenID: Data = Data()

  var quant: Int64 = 0

  var expected: Int64 = 0

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "protocol"

extension Protocol_ExchangeCreateContract: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".ExchangeCreateContract"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "owner_address"),
    2: .standard(proto: "first_token_id"),
    3: .standard(proto: "first_token_balance"),
    4: .standard(proto: "second_token_id"),
    5: .standard(proto: "second_token_balance"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularBytesField(value: &self.ownerAddress) }()
      case 2: try { try decoder.decodeSingularBytesField(value: &self.firstTokenID) }()
      case 3: try { try decoder.decodeSingularInt64Field(value: &self.firstTokenBalance) }()
      case 4: try { try decoder.decodeSingularBytesField(value: &self.secondTokenID) }()
      case 5: try { try decoder.decodeSingularInt64Field(value: &self.secondTokenBalance) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.ownerAddress.isEmpty {
      try visitor.visitSingularBytesField(value: self.ownerAddress, fieldNumber: 1)
    }
    if !self.firstTokenID.isEmpty {
      try visitor.visitSingularBytesField(value: self.firstTokenID, fieldNumber: 2)
    }
    if self.firstTokenBalance != 0 {
      try visitor.visitSingularInt64Field(value: self.firstTokenBalance, fieldNumber: 3)
    }
    if !self.secondTokenID.isEmpty {
      try visitor.visitSingularBytesField(value: self.secondTokenID, fieldNumber: 4)
    }
    if self.secondTokenBalance != 0 {
      try visitor.visitSingularInt64Field(value: self.secondTokenBalance, fieldNumber: 5)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Protocol_ExchangeCreateContract, rhs: Protocol_ExchangeCreateContract) -> Bool {
    if lhs.ownerAddress != rhs.ownerAddress {return false}
    if lhs.firstTokenID != rhs.firstTokenID {return false}
    if lhs.firstTokenBalance != rhs.firstTokenBalance {return false}
    if lhs.secondTokenID != rhs.secondTokenID {return false}
    if lhs.secondTokenBalance != rhs.secondTokenBalance {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Protocol_ExchangeInjectContract: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".ExchangeInjectContract"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "owner_address"),
    2: .standard(proto: "exchange_id"),
    3: .standard(proto: "token_id"),
    4: .same(proto: "quant"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularBytesField(value: &self.ownerAddress) }()
      case 2: try { try decoder.decodeSingularInt64Field(value: &self.exchangeID) }()
      case 3: try { try decoder.decodeSingularBytesField(value: &self.tokenID) }()
      case 4: try { try decoder.decodeSingularInt64Field(value: &self.quant) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.ownerAddress.isEmpty {
      try visitor.visitSingularBytesField(value: self.ownerAddress, fieldNumber: 1)
    }
    if self.exchangeID != 0 {
      try visitor.visitSingularInt64Field(value: self.exchangeID, fieldNumber: 2)
    }
    if !self.tokenID.isEmpty {
      try visitor.visitSingularBytesField(value: self.tokenID, fieldNumber: 3)
    }
    if self.quant != 0 {
      try visitor.visitSingularInt64Field(value: self.quant, fieldNumber: 4)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Protocol_ExchangeInjectContract, rhs: Protocol_ExchangeInjectContract) -> Bool {
    if lhs.ownerAddress != rhs.ownerAddress {return false}
    if lhs.exchangeID != rhs.exchangeID {return false}
    if lhs.tokenID != rhs.tokenID {return false}
    if lhs.quant != rhs.quant {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Protocol_ExchangeWithdrawContract: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".ExchangeWithdrawContract"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "owner_address"),
    2: .standard(proto: "exchange_id"),
    3: .standard(proto: "token_id"),
    4: .same(proto: "quant"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularBytesField(value: &self.ownerAddress) }()
      case 2: try { try decoder.decodeSingularInt64Field(value: &self.exchangeID) }()
      case 3: try { try decoder.decodeSingularBytesField(value: &self.tokenID) }()
      case 4: try { try decoder.decodeSingularInt64Field(value: &self.quant) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.ownerAddress.isEmpty {
      try visitor.visitSingularBytesField(value: self.ownerAddress, fieldNumber: 1)
    }
    if self.exchangeID != 0 {
      try visitor.visitSingularInt64Field(value: self.exchangeID, fieldNumber: 2)
    }
    if !self.tokenID.isEmpty {
      try visitor.visitSingularBytesField(value: self.tokenID, fieldNumber: 3)
    }
    if self.quant != 0 {
      try visitor.visitSingularInt64Field(value: self.quant, fieldNumber: 4)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Protocol_ExchangeWithdrawContract, rhs: Protocol_ExchangeWithdrawContract) -> Bool {
    if lhs.ownerAddress != rhs.ownerAddress {return false}
    if lhs.exchangeID != rhs.exchangeID {return false}
    if lhs.tokenID != rhs.tokenID {return false}
    if lhs.quant != rhs.quant {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Protocol_ExchangeTransactionContract: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".ExchangeTransactionContract"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "owner_address"),
    2: .standard(proto: "exchange_id"),
    3: .standard(proto: "token_id"),
    4: .same(proto: "quant"),
    5: .same(proto: "expected"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularBytesField(value: &self.ownerAddress) }()
      case 2: try { try decoder.decodeSingularInt64Field(value: &self.exchangeID) }()
      case 3: try { try decoder.decodeSingularBytesField(value: &self.tokenID) }()
      case 4: try { try decoder.decodeSingularInt64Field(value: &self.quant) }()
      case 5: try { try decoder.decodeSingularInt64Field(value: &self.expected) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.ownerAddress.isEmpty {
      try visitor.visitSingularBytesField(value: self.ownerAddress, fieldNumber: 1)
    }
    if self.exchangeID != 0 {
      try visitor.visitSingularInt64Field(value: self.exchangeID, fieldNumber: 2)
    }
    if !self.tokenID.isEmpty {
      try visitor.visitSingularBytesField(value: self.tokenID, fieldNumber: 3)
    }
    if self.quant != 0 {
      try visitor.visitSingularInt64Field(value: self.quant, fieldNumber: 4)
    }
    if self.expected != 0 {
      try visitor.visitSingularInt64Field(value: self.expected, fieldNumber: 5)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Protocol_ExchangeTransactionContract, rhs: Protocol_ExchangeTransactionContract) -> Bool {
    if lhs.ownerAddress != rhs.ownerAddress {return false}
    if lhs.exchangeID != rhs.exchangeID {return false}
    if lhs.tokenID != rhs.tokenID {return false}
    if lhs.quant != rhs.quant {return false}
    if lhs.expected != rhs.expected {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
