public extension Reflectable where Self: Decodable {
    static func reflectProperties(depth: Int) throws -> [ReflectedProperty] {
        return try decodeProperties(depth: depth)
    }

    static func anyReflectProperty(valueType: Any.Type, keyPath: AnyKeyPath) throws -> ReflectedProperty? {
        return try anyDecodeProperty(valueType: valueType, keyPath: keyPath)
    }
}

public extension Decodable {
    static func decodeProperties(depth: Int) throws -> [ReflectedProperty] {
        let context = ReflectionDecoderContext(activeOffset: 0, maxDepth: 42)
        let decoder = ReflectionDecoder(codingPath: [], context: context)
        _ = try Self(from: decoder)
        return context.properties.filter { $0.path.count == depth + 1 }
    }

    static func decodeProperty<T>(forKey keyPath: KeyPath<Self, T>) throws -> ReflectedProperty? {
        return try anyDecodeProperty(valueType: T.self, keyPath: keyPath)
    }

    static func anyDecodeProperty(valueType: Any.Type, keyPath: AnyKeyPath) throws -> ReflectedProperty? {
        guard valueType is AnyReflectionDecodable.Type else {
            throw ReflectableError.doesNotConform
        }

        if let cached = ReflectedPropertyCache.storage[keyPath] {
            return cached
        }

        var maxDepth = 0
        while true {
            defer { maxDepth += 1 }
            var activeOffset = 0

            if maxDepth > 42 {
                return nil
            }

            b: while true {
                defer { activeOffset += 1 }
                let context = ReflectionDecoderContext(activeOffset: activeOffset, maxDepth: maxDepth)
                let decoder = ReflectionDecoder(codingPath: [], context: context)

                let decoded = try Self(from: decoder)
                guard let codingPath = context.activeCodingPath else {
                    // no more values are being set at this depth
                    break b
                }

                guard let type = valueType as? AnyReflectionDecodable.Type, let left = decoded[keyPath: keyPath] else {
                    break b
                }

                if try type.anyReflectDecodedIsLeft(left) {
                    let property = ReflectedProperty(any: valueType, at: codingPath.map { $0.stringValue })
                    ReflectedPropertyCache.storage[keyPath] = property
                    return property
                }
            }
        }
    }
}

enum ReflectedPropertyCache {
    static var storage = [AnyKeyPath: ReflectedProperty]()
}
