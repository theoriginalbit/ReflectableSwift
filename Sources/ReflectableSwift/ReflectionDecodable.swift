import Foundation

public protocol ReflectionDecodable: AnyReflectionDecodable {
    static func reflectDecoded() throws -> (Self, Self)

    static func reflectDecodedIsLeft(_ item: Self) throws -> Bool
}

public extension ReflectionDecodable where Self: Equatable {
    static func reflectDecodedIsLeft(_ item: Self) throws -> Bool {
        return try Self.reflectDecoded().0 == item
    }
}

// MARK: Types

extension String: ReflectionDecodable {
    public static func reflectDecoded() -> (String, String) { return ("0", "1") }
}

public extension FixedWidthInteger {
    static func reflectDecoded() -> (Self, Self) { return (0, 1) }
}

extension UInt: ReflectionDecodable {}
extension UInt8: ReflectionDecodable {}
extension UInt16: ReflectionDecodable {}
extension UInt32: ReflectionDecodable {}
extension UInt64: ReflectionDecodable {}

extension Int: ReflectionDecodable {}
extension Int8: ReflectionDecodable {}
extension Int16: ReflectionDecodable {}
extension Int32: ReflectionDecodable {}
extension Int64: ReflectionDecodable {}

extension Bool: ReflectionDecodable {
    public static func reflectDecoded() -> (Bool, Bool) { return (false, true) }
}

public extension BinaryFloatingPoint {
    static func reflectDecoded() -> (Self, Self) { return (0, 1) }
}

extension Decimal: ReflectionDecodable {
    public static func reflectDecoded() -> (Decimal, Decimal) { return (0, 1) }
}

extension Float: ReflectionDecodable {}
extension Double: ReflectionDecodable {}

extension UUID: ReflectionDecodable {
    public static func reflectDecoded() -> (UUID, UUID) {
        let left = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1))
        let right = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2))
        return (left, right)
    }
}

extension Data: ReflectionDecodable {
    public static func reflectDecoded() -> (Data, Data) {
        let left = Data([0x00])
        let right = Data([0x01])
        return (left, right)
    }
}

extension Date: ReflectionDecodable {
    public static func reflectDecoded() -> (Date, Date) {
        let left = Date(timeIntervalSince1970: 1)
        let right = Date(timeIntervalSince1970: 0)
        return (left, right)
    }
}

extension Optional: ReflectionDecodable {
    public static func reflectDecoded() throws -> (Wrapped?, Wrapped?) {
        let reflected = try forceCast(Wrapped.self).anyReflectDecoded()
        return (reflected.0 as? Wrapped, reflected.1 as? Wrapped)
    }

    public static func reflectDecodedIsLeft(_ item: Wrapped?) throws -> Bool {
        guard let wrapped = item else {
            return false
        }
        return try forceCast(Wrapped.self).anyReflectDecodedIsLeft(wrapped)
    }
}

extension Array: ReflectionDecodable {
    public static func reflectDecoded() throws -> ([Element], [Element]) {
        let reflected = try forceCast(Element.self).anyReflectDecoded()
        // swiftlint:disable:next force_cast
        return ([reflected.0 as! Element], [reflected.1 as! Element])
    }

    public static func reflectDecodedIsLeft(_ item: [Element]) throws -> Bool {
        return try forceCast(Element.self).anyReflectDecodedIsLeft(item[0])
    }
}

// swiftlint:disable force_unwrapping

extension Dictionary: ReflectionDecodable {
    public static func reflectDecoded() throws -> ([Key: Value], [Key: Value]) {
        let reflectedValue = try forceCast(Value.self).anyReflectDecoded()
        let reflectedKey = try forceCast(Key.self).anyReflectDecoded()
        // swiftlint:disable:next force_cast
        let key = reflectedKey.0 as! Key
        // swiftlint:disable:next force_cast
        return ([key: reflectedValue.0 as! Value], [key: reflectedValue.1 as! Value])
    }

    public static func reflectDecodedIsLeft(_ item: [Key: Value]) throws -> Bool {
        let reflectedKey = try forceCast(Key.self).anyReflectDecoded()
        // swiftlint:disable:next force_cast
        let key = reflectedKey.0 as! Key
        return try forceCast(Value.self).anyReflectDecodedIsLeft(item[key]!)
    }
}

extension Set: ReflectionDecodable {
    public static func reflectDecoded() throws -> (Set<Element>, Set<Element>) {
        let reflected = try forceCast(Element.self).anyReflectDecoded()
        // swiftlint:disable:next force_cast
        return ([reflected.0 as! Element], [reflected.1 as! Element])
    }

    public static func reflectDecodedIsLeft(_ item: Set<Element>) throws -> Bool {
        return try forceCast(Element.self).anyReflectDecodedIsLeft(item.first!)
    }
}

extension URL: ReflectionDecodable {
    public static func reflectDecoded() throws -> (URL, URL) {
        let left = URL(string: "https://left.fake.url")!
        let right = URL(string: "https://right.fake.url")!
        return (left, right)
    }
}

// swiftlint:enable force_unwrapping

// MARK: Type Erased

public protocol AnyReflectionDecodable {
    static func anyReflectDecoded() throws -> (Any, Any)

    static func anyReflectDecodedIsLeft(_ any: Any) throws -> Bool
}

public extension ReflectionDecodable {
    static func anyReflectDecoded() throws -> (Any, Any) {
        let reflected = try reflectDecoded()
        return (reflected.0, reflected.1)
    }

    static func anyReflectDecodedIsLeft(_ any: Any) throws -> Bool {
        // swiftlint:disable:next force_cast
        return try reflectDecodedIsLeft(any as! Self)
    }
}

func forceCast<T>(_ type: T.Type) throws -> AnyReflectionDecodable.Type {
    guard let casted = T.self as? AnyReflectionDecodable.Type else {
        throw ReflectableError.doesNotConform
    }
    return casted
}

public extension ReflectionDecodable where Self: CaseIterable {
    static func reflectDecoded() throws -> (Self, Self) {
        guard allCases.count > 1, let first = allCases.first, let last = allCases.suffix(1).first else {
            throw ReflectableError.insufficientCaseCount
        }
        return (first, last)
    }
}
