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
            continuation.resume(returning: val)
        }
        cancellables.insert(p)
    }
}
private func remove(cancellable:AnyCancellable) {
    cancellables.remove(cancellable)
}
/// Converts any never failing publisher into an async function. A good option when using URLSession on iOS 13
/// - warning: This function is be used with publishers that finishes once.
/// - Returns: T
public func makeAsync<T:Any>(_ publisher:AnyPublisher<T,Never>) async -> T  {
    return await withCheckedContinuation { continuation in
        var p:AnyCancellable?
        p = publisher.sink { compl in
            cancellables.remove(p)
        } receiveValue: { val in
            continuation.resume(returning: val)
        }
        cancellables.insert(p)
    }
}
/// Converts any never failing publisher into an async function. A good option when using URLSession on iOS 13
/// - warning: This function is be used with publishers that finishes once.
/// - Returns: T
public func makeAsyncStream<T:Any>(_ publisher:AnyPublisher<T,Never>) -> AsyncStream<T>  {
    AsyncStream { continuation in
        let c = publisher.sink { compl in
            continuation.finish()
        } receiveValue: { val in
            continuation.yield(val)
        }
        cancellables.insert(c)
        continuation.onTermination = { @Sendable [c] termination in
            Task {
                remove(cancellable: c)
            }
        }
    }
}
/// Converts any never failing publisher into an async function. A good option when using URLSession on iOS 13
/// - warning: This function is be used with publishers that finishes once.
/// - Returns: T
public func makeAsyncThrowingStream<T:Any>(_ publisher:AnyPublisher<T,Error>) -> AsyncThrowingStream<T,Error>  {
    AsyncThrowingStream { continuation in
        let c = publisher.sink { compl in
            switch compl {
            case .failure(let error): continuation.finish(throwing: error)
            case .finished: continuation.finish(throwing: nil)
            }
        } receiveValue: { val in
            continuation.yield(val)
        }
        cancellables.insert(c)
        continuation.onTermination = { @Sendable [c] termination in
            Task {
                remove(cancellable: c)
            }
        }
    }
}
