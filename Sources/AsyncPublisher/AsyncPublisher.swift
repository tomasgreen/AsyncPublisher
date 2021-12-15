import Combine
private var cancellables = Set<AnyCancellable?>()

/// Converts any failing publisher into an async function.
/// - warning: This function is be used with publishers that finishes once.
/// - Returns: T
public func makeAsync<T:Any>(_ publisher:AnyPublisher<T,Error>) async throws -> T  {
    return try await withCheckedThrowingContinuation { continuation in
        var p:AnyCancellable?
        p = publisher.sink { compl in
            if case let .failure(err) = compl {
                continuation.resume(throwing: err)
            }
            cancellables.remove(p)
        } receiveValue: { val in
            cancellables.remove(p)
            continuation.resume(returning: val)
        }
        cancellables.insert(p)
    }
}
/// Converts any never failing publisher into an async function. A good option when using URLSession on iOS 13
/// - warning: This function is be used with publishers that finishes once.
/// - Returns: T
public func makeAsync<T:Any>(_ publisher:AnyPublisher<T,Never>) async -> T  {
    return await withCheckedContinuation { continuation in
        var p:AnyCancellable?
        p = publisher.sink { val in
            cancellables.remove(p)
            continuation.resume(returning: val)
        }
        cancellables.insert(p)
    }
}
