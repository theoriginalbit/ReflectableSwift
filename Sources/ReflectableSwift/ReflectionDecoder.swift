final class ReflectionDecoderContext {
    var activeCodingPath: [CodingKey]?

    var maxDepth: Int

    var properties: [ReflectedProperty]

    var isActive: Bool {
        defer { currentOffset += 1 }
        return currentOffset == activeOffset
    }

    private var activeOffset: Int

    private var currentOffset: Int

    init(activeOffset: Int, maxDepth: Int) {
        activeCodingPath = nil
        self.maxDepth = maxDepth
        properties = []
        self.activeOffset = activeOffset
        currentOffset = 0
    }

    func addProperty<T>(type: T.Type, at path: [CodingKey]) {
        let path = path.map { $0.stringValue }
        // remove any duplicates, favoring the new type
        properties = properties.filter { $0.path != path }
        let property = ReflectedProperty(T.self, at: path)
        properties.append(property)
    }
}

struct ReflectionDecoder: Decoder {
    var codingPath: [CodingKey]
    var context: ReflectionDecoderContext
    var userInfo: [CodingUserInfoKey: Any] { return [:] }

    init(codingPath: [CodingKey], context: ReflectionDecoderContext) {
        self.codingPath = codingPath
        self.context = context
    }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        return .init(ReflectionKeyedDecoder<Key>(codingPath: codingPath, context: context))
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return ReflectionUnkeyedDecoder(codingPath: codingPath, context: context)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return ReflectionSingleValueDecoder(codingPath: codingPath, context: context)
    }
}

struct ReflectionSingleValueDecoder: SingleValueDecodingContainer {
    var codingPath: [CodingKey]
    var context: ReflectionDecoderContext

    init(codingPath: [CodingKey], context: ReflectionDecoderContext) {
        self.codingPath = codingPath
        self.context = context
    }

    func decodeNil() -> Bool {
        return false
    }

    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        context.addProperty(type: T.self, at: codingPath)
        let type = try forceCast(T.self)
        let reflected = try type.anyReflectDecoded()
        if context.isActive {
            context.activeCodingPath = codingPath
            // swiftlint:disable:next force_cast
            return reflected.0 as! T
        }
        // swiftlint:disable:next force_cast
        return reflected.1 as! T
    }
}

final class ReflectionKeyedDecoder<K>: KeyedDecodingContainerProtocol where K: CodingKey {
    typealias Key = K

    var allKeys: [K] { return [] }
    var codingPath: [CodingKey]
    var context: ReflectionDecoderContext
    var nextIsOptional: Bool

    init(codingPath: [CodingKey], context: ReflectionDecoderContext) {
        self.codingPath = codingPath
        self.context = context
        nextIsOptional = false
    }

    func contains(_ key: K) -> Bool {
        nextIsOptional = true
        return true
    }

    func decodeNil(forKey key: K) throws -> Bool {
        if context.maxDepth > codingPath.count {
            return false
        }
        return true
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        return .init(ReflectionKeyedDecoder<NestedKey>(codingPath: codingPath + [key], context: context))
    }

    func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        return ReflectionUnkeyedDecoder(codingPath: codingPath + [key], context: context)
    }

    func superDecoder() throws -> Decoder {
        return ReflectionDecoder(codingPath: codingPath, context: context)
    }

    func superDecoder(forKey key: K) throws -> Decoder {
        return ReflectionDecoder(codingPath: codingPath + [key], context: context)
    }

    func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T: Decodable {
        if nextIsOptional {
            context.addProperty(type: T?.self, at: codingPath + [key])
            nextIsOptional = false
        } else {
            context.addProperty(type: T.self, at: codingPath + [key])
        }
        if let type = T.self as? AnyReflectionDecodable.Type, let reflected = try? type.anyReflectDecoded() {
            if context.isActive {
                context.activeCodingPath = codingPath + [key]
                // swiftlint:disable:next force_cast
                return reflected.0 as! T
            }
            // swiftlint:disable:next force_cast
            return reflected.1 as! T
        } else {
            let decoder = ReflectionDecoder(codingPath: codingPath + [key], context: context)
            return try T(from: decoder)
        }
    }
}

private struct ReflectionUnkeyedDecoder: UnkeyedDecodingContainer {
    var count: Int?
    var isAtEnd: Bool
    var currentIndex: Int
    var codingPath: [CodingKey]
    var context: ReflectionDecoderContext

    init(codingPath: [CodingKey], context: ReflectionDecoderContext) {
        self.codingPath = codingPath
        self.context = context
        currentIndex = 0
        if context.isActive {
            count = 1
            isAtEnd = false
            context.activeCodingPath = codingPath
        } else {
            count = 0
            isAtEnd = true
        }
    }

    mutating func decodeNil() throws -> Bool {
        isAtEnd = true
        return true
    }

    mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        context.addProperty(type: [T].self, at: codingPath)
        isAtEnd = true
        if let type = T.self as? AnyReflectionDecodable.Type, let reflected = try? type.anyReflectDecoded() {
            // swiftlint:disable:next force_cast
            return reflected.0 as! T
        } else {
            let decoder = ReflectionDecoder(codingPath: codingPath, context: context)
            return try T(from: decoder)
        }
    }

    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        return .init(ReflectionKeyedDecoder<NestedKey>(codingPath: codingPath, context: context))
    }

    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        return ReflectionUnkeyedDecoder(codingPath: codingPath, context: context)
    }

    mutating func superDecoder() throws -> Decoder {
        return ReflectionDecoder(codingPath: codingPath, context: context)
    }
}
