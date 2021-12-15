# AsyncPublisher

Since the release of combine some have made it a habit of using publishers instead of completion handlers for a lot of things, like network requests. 
Swift 5.5 and the new Concurrency apis came with some pretty obvions advatanges but sadly it was not bacwards compatible with older iOS versions until the release of Xcode 13.2. 
However, the release did not make the new async apis (like async functuons in URLSession) available for older systems (iOS 15.0 and above only). 

## Solution
To solve this issue and expose async functions of one:s combine apis you can use the `withCheckedThrowingContinuation` or `withCheckedContinuation` feature.
This package exposes two functions that take any publisher and makes it async, like this:

```swift
class MyClass {
    func getMyValuePublisher() -> AnyPublisher<MyValue,Error> {
        return URLSession.shared.dataTaskPublisher(for: myServerURL)
            .map { $0.data }
            .decode(type: MyValue.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    func myValue() async throws -> MyValue {
        try await makeAsync(getMyValuePublisher())
    }
}

```
