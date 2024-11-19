// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: value.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

import Foundation
@preconcurrency import SwiftProtobuf    // TODO: Andrey Fedorov - Remove after migration to Swift 6 structured concurrency (IOS-8369)

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

struct Koinos_Chain_value_type {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var kind: Koinos_Chain_value_type.OneOf_Kind? = nil

  var messageValue: SwiftProtobuf.Google_Protobuf_Any {
    get {
      if case .messageValue(let v)? = kind {return v}
      return SwiftProtobuf.Google_Protobuf_Any()
    }
    set {kind = .messageValue(newValue)}
  }

  var int32Value: Int32 {
    get {
      if case .int32Value(let v)? = kind {return v}
      return 0
    }
    set {kind = .int32Value(newValue)}
  }

  var int64Value: Int64 {
    get {
      if case .int64Value(let v)? = kind {return v}
      return 0
    }
    set {kind = .int64Value(newValue)}
  }

  var uint32Value: UInt32 {
    get {
      if case .uint32Value(let v)? = kind {return v}
      return 0
    }
    set {kind = .uint32Value(newValue)}
  }

  var uint64Value: UInt64 {
    get {
      if case .uint64Value(let v)? = kind {return v}
      return 0
    }
    set {kind = .uint64Value(newValue)}
  }

  var sint32Value: Int32 {
    get {
      if case .sint32Value(let v)? = kind {return v}
      return 0
    }
    set {kind = .sint32Value(newValue)}
  }

  var sint64Value: Int64 {
    get {
      if case .sint64Value(let v)? = kind {return v}
      return 0
    }
    set {kind = .sint64Value(newValue)}
  }

  var fixed32Value: UInt32 {
    get {
      if case .fixed32Value(let v)? = kind {return v}
      return 0
    }
    set {kind = .fixed32Value(newValue)}
  }

  var fixed64Value: UInt64 {
    get {
      if case .fixed64Value(let v)? = kind {return v}
      return 0
    }
    set {kind = .fixed64Value(newValue)}
  }

  var sfixed32Value: Int32 {
    get {
      if case .sfixed32Value(let v)? = kind {return v}
      return 0
    }
    set {kind = .sfixed32Value(newValue)}
  }

  var sfixed64Value: Int64 {
    get {
      if case .sfixed64Value(let v)? = kind {return v}
      return 0
    }
    set {kind = .sfixed64Value(newValue)}
  }

  var boolValue: Bool {
    get {
      if case .boolValue(let v)? = kind {return v}
      return false
    }
    set {kind = .boolValue(newValue)}
  }

  var stringValue: String {
    get {
      if case .stringValue(let v)? = kind {return v}
      return String()
    }
    set {kind = .stringValue(newValue)}
  }

  var bytesValue: Data {
    get {
      if case .bytesValue(let v)? = kind {return v}
      return Data()
    }
    set {kind = .bytesValue(newValue)}
  }

  var unknownFields = SwiftProtobuf.UnknownStorage()

  enum OneOf_Kind: Equatable {
    case messageValue(SwiftProtobuf.Google_Protobuf_Any)
    case int32Value(Int32)
    case int64Value(Int64)
    case uint32Value(UInt32)
    case uint64Value(UInt64)
    case sint32Value(Int32)
    case sint64Value(Int64)
    case fixed32Value(UInt32)
    case fixed64Value(UInt64)
    case sfixed32Value(Int32)
    case sfixed64Value(Int64)
    case boolValue(Bool)
    case stringValue(String)
    case bytesValue(Data)

  #if !swift(>=4.1)
    static func ==(lhs: Koinos_Chain_value_type.OneOf_Kind, rhs: Koinos_Chain_value_type.OneOf_Kind) -> Bool {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch (lhs, rhs) {
      case (.messageValue, .messageValue): return {
        guard case .messageValue(let l) = lhs, case .messageValue(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.int32Value, .int32Value): return {
        guard case .int32Value(let l) = lhs, case .int32Value(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.int64Value, .int64Value): return {
        guard case .int64Value(let l) = lhs, case .int64Value(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.uint32Value, .uint32Value): return {
        guard case .uint32Value(let l) = lhs, case .uint32Value(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.uint64Value, .uint64Value): return {
        guard case .uint64Value(let l) = lhs, case .uint64Value(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.sint32Value, .sint32Value): return {
        guard case .sint32Value(let l) = lhs, case .sint32Value(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.sint64Value, .sint64Value): return {
        guard case .sint64Value(let l) = lhs, case .sint64Value(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.fixed32Value, .fixed32Value): return {
        guard case .fixed32Value(let l) = lhs, case .fixed32Value(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.fixed64Value, .fixed64Value): return {
        guard case .fixed64Value(let l) = lhs, case .fixed64Value(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.sfixed32Value, .sfixed32Value): return {
        guard case .sfixed32Value(let l) = lhs, case .sfixed32Value(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.sfixed64Value, .sfixed64Value): return {
        guard case .sfixed64Value(let l) = lhs, case .sfixed64Value(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.boolValue, .boolValue): return {
        guard case .boolValue(let l) = lhs, case .boolValue(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.stringValue, .stringValue): return {
        guard case .stringValue(let l) = lhs, case .stringValue(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      case (.bytesValue, .bytesValue): return {
        guard case .bytesValue(let l) = lhs, case .bytesValue(let r) = rhs else { preconditionFailure() }
        return l == r
      }()
      default: return false
      }
    }
  #endif
  }

  init() {}
}

struct Koinos_Chain_enum_type {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var name: String = String()

  var number: Int32 = 0

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

struct Koinos_Chain_list_type {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var values: [Koinos_Chain_value_type] = []

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

#if swift(>=5.5) && canImport(_Concurrency)
extension Koinos_Chain_value_type: @unchecked Sendable {}
extension Koinos_Chain_value_type.OneOf_Kind: @unchecked Sendable {}
extension Koinos_Chain_enum_type: @unchecked Sendable {}
extension Koinos_Chain_list_type: @unchecked Sendable {}
#endif  // swift(>=5.5) && canImport(_Concurrency)

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "koinos.chain"

extension Koinos_Chain_value_type: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".value_type"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "message_value"),
    2: .standard(proto: "int32_value"),
    3: .standard(proto: "int64_value"),
    4: .standard(proto: "uint32_value"),
    5: .standard(proto: "uint64_value"),
    6: .standard(proto: "sint32_value"),
    7: .standard(proto: "sint64_value"),
    8: .standard(proto: "fixed32_value"),
    9: .standard(proto: "fixed64_value"),
    10: .standard(proto: "sfixed32_value"),
    11: .standard(proto: "sfixed64_value"),
    12: .standard(proto: "bool_value"),
    13: .standard(proto: "string_value"),
    14: .standard(proto: "bytes_value"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try {
        var v: SwiftProtobuf.Google_Protobuf_Any?
        var hadOneofValue = false
        if let current = self.kind {
          hadOneofValue = true
          if case .messageValue(let m) = current {v = m}
        }
        try decoder.decodeSingularMessageField(value: &v)
        if let v = v {
          if hadOneofValue {try decoder.handleConflictingOneOf()}
          self.kind = .messageValue(v)
        }
      }()
      case 2: try {
        var v: Int32?
        try decoder.decodeSingularInt32Field(value: &v)
        if let v = v {
          if self.kind != nil {try decoder.handleConflictingOneOf()}
          self.kind = .int32Value(v)
        }
      }()
      case 3: try {
        var v: Int64?
        try decoder.decodeSingularInt64Field(value: &v)
        if let v = v {
          if self.kind != nil {try decoder.handleConflictingOneOf()}
          self.kind = .int64Value(v)
        }
      }()
      case 4: try {
        var v: UInt32?
        try decoder.decodeSingularUInt32Field(value: &v)
        if let v = v {
          if self.kind != nil {try decoder.handleConflictingOneOf()}
          self.kind = .uint32Value(v)
        }
      }()
      case 5: try {
        var v: UInt64?
        try decoder.decodeSingularUInt64Field(value: &v)
        if let v = v {
          if self.kind != nil {try decoder.handleConflictingOneOf()}
          self.kind = .uint64Value(v)
        }
      }()
      case 6: try {
        var v: Int32?
        try decoder.decodeSingularSInt32Field(value: &v)
        if let v = v {
          if self.kind != nil {try decoder.handleConflictingOneOf()}
          self.kind = .sint32Value(v)
        }
      }()
      case 7: try {
        var v: Int64?
        try decoder.decodeSingularSInt64Field(value: &v)
        if let v = v {
          if self.kind != nil {try decoder.handleConflictingOneOf()}
          self.kind = .sint64Value(v)
        }
      }()
      case 8: try {
        var v: UInt32?
        try decoder.decodeSingularFixed32Field(value: &v)
        if let v = v {
          if self.kind != nil {try decoder.handleConflictingOneOf()}
          self.kind = .fixed32Value(v)
        }
      }()
      case 9: try {
        var v: UInt64?
        try decoder.decodeSingularFixed64Field(value: &v)
        if let v = v {
          if self.kind != nil {try decoder.handleConflictingOneOf()}
          self.kind = .fixed64Value(v)
        }
      }()
      case 10: try {
        var v: Int32?
        try decoder.decodeSingularSFixed32Field(value: &v)
        if let v = v {
          if self.kind != nil {try decoder.handleConflictingOneOf()}
          self.kind = .sfixed32Value(v)
        }
      }()
      case 11: try {
        var v: Int64?
        try decoder.decodeSingularSFixed64Field(value: &v)
        if let v = v {
          if self.kind != nil {try decoder.handleConflictingOneOf()}
          self.kind = .sfixed64Value(v)
        }
      }()
      case 12: try {
        var v: Bool?
        try decoder.decodeSingularBoolField(value: &v)
        if let v = v {
          if self.kind != nil {try decoder.handleConflictingOneOf()}
          self.kind = .boolValue(v)
        }
      }()
      case 13: try {
        var v: String?
        try decoder.decodeSingularStringField(value: &v)
        if let v = v {
          if self.kind != nil {try decoder.handleConflictingOneOf()}
          self.kind = .stringValue(v)
        }
      }()
      case 14: try {
        var v: Data?
        try decoder.decodeSingularBytesField(value: &v)
        if let v = v {
          if self.kind != nil {try decoder.handleConflictingOneOf()}
          self.kind = .bytesValue(v)
        }
      }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    switch self.kind {
    case .messageValue?: try {
      guard case .messageValue(let v)? = self.kind else { preconditionFailure() }
      try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
    }()
    case .int32Value?: try {
      guard case .int32Value(let v)? = self.kind else { preconditionFailure() }
      try visitor.visitSingularInt32Field(value: v, fieldNumber: 2)
    }()
    case .int64Value?: try {
      guard case .int64Value(let v)? = self.kind else { preconditionFailure() }
      try visitor.visitSingularInt64Field(value: v, fieldNumber: 3)
    }()
    case .uint32Value?: try {
      guard case .uint32Value(let v)? = self.kind else { preconditionFailure() }
      try visitor.visitSingularUInt32Field(value: v, fieldNumber: 4)
    }()
    case .uint64Value?: try {
      guard case .uint64Value(let v)? = self.kind else { preconditionFailure() }
      try visitor.visitSingularUInt64Field(value: v, fieldNumber: 5)
    }()
    case .sint32Value?: try {
      guard case .sint32Value(let v)? = self.kind else { preconditionFailure() }
      try visitor.visitSingularSInt32Field(value: v, fieldNumber: 6)
    }()
    case .sint64Value?: try {
      guard case .sint64Value(let v)? = self.kind else { preconditionFailure() }
      try visitor.visitSingularSInt64Field(value: v, fieldNumber: 7)
    }()
    case .fixed32Value?: try {
      guard case .fixed32Value(let v)? = self.kind else { preconditionFailure() }
      try visitor.visitSingularFixed32Field(value: v, fieldNumber: 8)
    }()
    case .fixed64Value?: try {
      guard case .fixed64Value(let v)? = self.kind else { preconditionFailure() }
      try visitor.visitSingularFixed64Field(value: v, fieldNumber: 9)
    }()
    case .sfixed32Value?: try {
      guard case .sfixed32Value(let v)? = self.kind else { preconditionFailure() }
      try visitor.visitSingularSFixed32Field(value: v, fieldNumber: 10)
    }()
    case .sfixed64Value?: try {
      guard case .sfixed64Value(let v)? = self.kind else { preconditionFailure() }
      try visitor.visitSingularSFixed64Field(value: v, fieldNumber: 11)
    }()
    case .boolValue?: try {
      guard case .boolValue(let v)? = self.kind else { preconditionFailure() }
      try visitor.visitSingularBoolField(value: v, fieldNumber: 12)
    }()
    case .stringValue?: try {
      guard case .stringValue(let v)? = self.kind else { preconditionFailure() }
      try visitor.visitSingularStringField(value: v, fieldNumber: 13)
    }()
    case .bytesValue?: try {
      guard case .bytesValue(let v)? = self.kind else { preconditionFailure() }
      try visitor.visitSingularBytesField(value: v, fieldNumber: 14)
    }()
    case nil: break
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Koinos_Chain_value_type, rhs: Koinos_Chain_value_type) -> Bool {
    if lhs.kind != rhs.kind {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Koinos_Chain_enum_type: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".enum_type"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "name"),
    2: .same(proto: "number"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularStringField(value: &self.name) }()
      case 2: try { try decoder.decodeSingularInt32Field(value: &self.number) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.name.isEmpty {
      try visitor.visitSingularStringField(value: self.name, fieldNumber: 1)
    }
    if self.number != 0 {
      try visitor.visitSingularInt32Field(value: self.number, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Koinos_Chain_enum_type, rhs: Koinos_Chain_enum_type) -> Bool {
    if lhs.name != rhs.name {return false}
    if lhs.number != rhs.number {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Koinos_Chain_list_type: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".list_type"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "values"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeRepeatedMessageField(value: &self.values) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.values.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.values, fieldNumber: 1)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Koinos_Chain_list_type, rhs: Koinos_Chain_list_type) -> Bool {
    if lhs.values != rhs.values {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
