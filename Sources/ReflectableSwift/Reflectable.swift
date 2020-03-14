enum ReflectableError: Error {
    case doesNotConform
    case insufficientCaseCount
}

public protocol Reflectable: AnyReflectable {
    static func reflectProperty<T>(forKey keyPath: KeyPath<Self, T>) throws -> ReflectedProperty?
}

public extension Reflectable {
    static func reflectProperties() throws -> [ReflectedProperty] {
        return try reflectProperties(depth: 0)
    }

    static func reflectProperty<T>(forKey keyPath: KeyPath<Self, T>) throws -> ReflectedProperty? {
        return try anyReflectProperty(valueType: T.self, keyPath: keyPath)
    }
}

public protocol AnyReflectable {
    static func reflectProperties(depth: Int) throws -> [ReflectedProperty]

    static func anyReflectProperty(valueType: Any.Type, keyPath: AnyKeyPath) throws -> ReflectedProperty?
}

public struct ReflectedProperty {
    public let type: Any.Type

    public let path: [String]

    public init<T>(_ type: T.Type, at path: [String]) {
        self.type = T.self
        self.path = path
    }

    public init(any type: Any.Type, at path: [String]) {
        self.type = type
        self.path = path
    }
}

extension ReflectedProperty: CustomStringConvertible {
    public var description: String {
        return "\(path.joined(separator: ".")): \(type)"
    }
}
