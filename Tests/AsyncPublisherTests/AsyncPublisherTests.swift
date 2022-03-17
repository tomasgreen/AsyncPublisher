import XCTest
@testable import AsyncPublisher
import Combine

enum TestPublisherError : Error {
    case failed
}
func publisherStringErrorFinishing(string:String) -> AnyPublisher<String,Error> {
    let subj = PassthroughSubject<String,Error>()
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
        subj.send(string)
    }
    return subj.eraseToAnyPublisher()
}
func publisherStringErrorFailing(string:String) -> AnyPublisher<String,Error> {
    let subj = PassthroughSubject<String,Error>()
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
        subj.send(completion: .failure(TestPublisherError.failed))
    }
    return subj.eraseToAnyPublisher()
}
func publisherStringNeverFinishing(string:String) -> AnyPublisher<String,Never> {
    let subj = PassthroughSubject<String,Never>()
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
        subj.send(string)
    }
    return subj.eraseToAnyPublisher()
}

final class AsyncPublisherTests: XCTestCase {
    func testMakeAsync() async throws {
        let testString = "testing"
        do {
            _ = try await makeAsync(publisherStringErrorFailing(string:testString))
            XCTFail("Should not have made it this far")
        } catch {
            if error is TestPublisherError == false {
                XCTFail("wrong error?")
            }
        }
        let val = await makeAsync(publisherStringNeverFinishing(string: testString))
        XCTAssert(testString == val)
        let val2 = try await makeAsync(publisherStringErrorFinishing(string:testString))
        XCTAssert(testString == val2)
    }
    func testStream() async {
        let subj = PassthroughSubject<String,Never>()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            subj.send("test1")
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            subj.send("test2")
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
            subj.send(completion: .finished)
        }
        for await str in makeAsyncStream(subj.eraseToAnyPublisher()) {
            print(str)
        }
    }
}
