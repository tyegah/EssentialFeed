//
//  URLSessionHTTPClient.swift
//  EssentialFeedTests
//
//  Created by Ty Septiani on 17/09/22.
//

import XCTest
import EssentialFeed

// In order to test the URLSessionHTTPClient
// There are 4 ways to do it
// 1. End to end test which will be the least favored
// 2. Subclass based mocking -> Subclassing URLSession and creating URLSessionSpy & URLSessionDataTaskSpy. This method is dangerous because we're subclassing classes that we don't own
// 3. Protocol based mocking -. Creating our own protocol that mirrors the method in URLSession (dataTask(with url: URL,...) & URLSessionDataTask (resume()) that we're using. This method is also not very good because we're introducing protocols that we only use on tests to the production code
// 4. URL Protocol stubbing (the best way to do this). We're intercepting url requests by using this method,a nd stub the result without actually making the real request. URLProtocol is part of the URL Loading system. It can be used with other frameworks for URL requests such as AFNetworking, etc

class URLSessionHTTPClientTests: XCTestCase {
    
    // This test is now removed because it is redundant with the second test
//    func test_getFromURL_createsDataTaskWithURL() {
//        // ARRANGE
//        let url = URL(string: "https://a-url.com")!
//        // Here we're using subclass-based mocking which would be
//        // URLSessionSpy
//        let session = URLSessionSpy()
//        let sut = URLSessionHTTPClient(session: session)
//        sut.get(from: url)
//        XCTAssertEqual(session.requestedURLs, [url])
//    }
    
    // Since we are now intercepting requests through URLProtocol stubs
    // We no longer need this test
//    func test_getFromURL_resumesDataTaskWithURL() {
//        // ARRANGE
//        let url = URL(string: "https://a-url.com")!
//        // Here we're using subclass-based mocking which would be
//        // URLSessionSpy
//        let session = URLSessionSpy()
//        let task = URLSessionDataTaskSpy()
//        // stubbing behavior
//        session.stub(url: url, task: task)
//        let sut = URLSessionHTTPClient(session: session)
//        sut.get(from: url) { _ in }
//        XCTAssertEqual(task.resumesCallCount, 1)
//    }
    
    // Move the start/stop intercepting request to this setup/teardown methods
    // Because these methods will be called every time each test is run
    override func setUp() {
        super.setUp()
        // register the URLProtocol stub to start intercepting requests
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() {
        super.tearDown()
        // stop intercepting requests by unregistering the URLProtocol Stub
        URLProtocolStub.stopInterceptingRequests()
    }
    
    // Previously, We were putting the URL checking concerns inside the URLProtocol Stub and it's not a good practice
    // So we move the concern to a separate test that specifically checks for the URL
    func test_getFromURL_performsGETRequestWithURL() {
        // ARRANGE
        let url = anyURL()
        // ASSERT
        // Async assertion needs expectation
        let exp = expectation(description: "Wait for request")
        // Any data like body and params can be observed through this observer method
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        // ACT
        makeSUT().get(from: url) { _ in }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_failsOnRequestError() {
        // REFACTORED VERSION
        
        // Arrange
        let requestError = anyNSError()
        // act
        let receivedError = resultErrorFor(data: nil, response: nil, error: requestError)
        // assert
        // We need to do this because the error returned from URLProtocol somehow has additional userInfo in it
        XCTAssertEqual((receivedError as? NSError)?.domain, requestError.domain)
        XCTAssertEqual((receivedError as? NSError)?.code, requestError.code)
        
//        // ARRANGE
////        URLProtocolStub.startInterceptingRequests()
//        let error = NSError(domain: "any-error", code: 1)
//        // Here we're using subclass-based mocking which would be
//        // URLSessionSpy
////        let session = URLSessionSpy()
//        // stubbing behavior
//        URLProtocolStub.stub(data: nil, response: nil, error: error)
//
//        // Here we start to need to see the result for the error
//        // So we change the production code which is the get(from:URL) method
//        // To have completion handler to get the result
//        let exp = expectation(description: "Wait for result")
//        makeSUT().get(from: anyURL()) { result in
//            switch result {
//            case let .failure(receivedError as NSError):
////                XCTAssertEqual(error, receivedError)
//                // we need to check for domain and code because somehow
//                // the URLProtocol returns an NSError with additional userInfo that we never add
//                XCTAssertEqual(receivedError.domain, error.domain)
//                XCTAssertEqual(receivedError.code, error.code)
//            default:
//                XCTFail("Expected failure \(error), got \(result) instead")
//            }
//            exp.fulfill()
//        }
//        wait(for: [exp], timeout: 1.0)
        // stop intercepting requests by unregistering the URLProtocol Stub
//        URLProtocolStub.stopInterceptingRequests()
    }
    
    // This is to test all the edge cases/possibility for URLSession data (Data?, URLResponse?, Error?)
    // This one is to handle the nil data, nil URLResponse and nil Error
//    func test_getFromURL_failsOnAllNilValues() {
    
    // Now we renamed the method because we decided to test all the invalid cases here in one test
    // There are 10 invalid cases/possibility in this scenario
    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        // REFACTORED VERSION
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: nil))
        // This invalid case (nil data, response, and nil error) is moved to its own test
        // test_getFromURL_succeedsOnHTTPURLResponseWithEmptyData
        // Because it turns out that the URL Loading system always returns data (0 bytes) even if we set it to nil
//        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil))
//        // ARRANGE
//        URLProtocolStub.stub(data: nil, response: nil, error: nil)
//
//        let exp = expectation(description: "Wait for result")
//        makeSUT().get(from: anyURL()) { result in
//            switch result {
//                // Because there is no error here
//                // We only need to make sure that it will cause failure
//                // We do not care about the type of error thrown in this case
//                // We choose not to care because this is an invalid scenario
//            case .failure:
//                break
//            default:
//                XCTFail("Expected failure, got \(result) instead")
//            }
//            exp.fulfill()
//        }
//        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_succeedsOnHTTPURLResponseWithData() {
        // arrange
        let data = anyData()
        let response = anyHTTPURLResponse()
        //act
        let receivedResult = resultValuesFor(data: data, response: response, error: nil)
        //assert
        XCTAssertEqual(receivedResult?.data, data)
        XCTAssertEqual(receivedResult?.response.url, response.url)
        XCTAssertEqual(receivedResult?.response.statusCode, response.statusCode)
    }
    
    func test_getFromURL_succeedsOnHTTPURLResponseWithEmptyData() {
        // arrange
        let response = anyHTTPURLResponse()
        let emptyData = Data()
        // act
        let receivedResult = resultValuesFor(data: nil, response: response, error: nil)
        //assert
        XCTAssertEqual(receivedResult?.data, emptyData)
        XCTAssertEqual(receivedResult?.response.url, response.url)
        XCTAssertEqual(receivedResult?.response.statusCode, response.statusCode)
    }
    
    // MARK: Helpers
    // Move the SUT creation to a helper/factory method to prevent breaking changes on the tests
    // For example when the instance will start having dependencies upon its creation, etc
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> HTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func resultValuesFor(data: Data?,
                                 response: URLResponse?,
                                 error:Error?,
                                 file: StaticString = #file,
                                 line: UInt = #line) -> (data: Data, response: HTTPURLResponse)? {
        // ARRANGE
        let result = resultFor(data: data, response: response, error: error, file: file, line: line)
        switch result {
            // Because there is no error here
            // We only need to make sure that it will cause failure
            // We do not care about the type of error thrown in this case
            // We choose not to care because this is an invalid scenario
        case let .success((data, response)):
            return (data, response)
        default:
            XCTFail("Expected failure, got \(result) instead", file: file, line: line)
            return nil
        }
    }
    
    private func resultErrorFor(data: Data?,
                                response: URLResponse?,
                                error: Error?,
                                file: StaticString = #file,
                                line: UInt = #line) -> Error? {
        // ARRANGE
        let result = resultFor(data: data, response: response, error: error, file: file, line: line)
        switch result {
            // Because there is no error here
            // We only need to make sure that it will cause failure
            // We do not care about the type of error thrown in this case
            // We choose not to care because this is an invalid scenario
        case let .failure(error):
            return error
        default:
            XCTFail("Expected failure, got \(result) instead", file: file, line: line)
            return nil
        }
    }
    
    private func resultFor(data: Data?,
                           response: URLResponse?,
                           error: Error?,
                           file: StaticString = #file,
                           line: UInt = #line) -> HTTPClientResult {
        // ARRANGE
        URLProtocolStub.stub(data: data, response: response, error: error)
        let sut = makeSUT(file: file, line: line)
        let exp = expectation(description: "Wait for completion")
        var receivedResult:HTTPClientResult!
        sut.get(from: anyURL()) { result in
            receivedResult = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return receivedResult
    }
    
    private func anyURL() -> URL {
        return URL(string: "https://any-url.com")!
    }
    
    private func anyData() -> Data {
        return Data("any-data".utf8)
    }
    
    private func anyHTTPURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(url: anyURL(), statusCode: 0, httpVersion: nil, headerFields: nil)!
    }
    
    private func nonHTTPURLResponse() -> URLResponse {
        return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    // We need to note that the URLProtocol is an abstract class, it is not a protocol
    // So here, we are actually still subclassing and not using a protocol
    private class URLProtocolStub: URLProtocol {
        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?
        
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error:Error?
        }
        
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            // Do not forget to reset all the variables on this method
            stub = nil
            requestObserver = nil
        }
        
        static func observeRequests(observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }
  
        // We need to override these 4 methods from URLProtocol in order to intercept URL requests
        override class func canInit(with request: URLRequest) -> Bool {
            // Remove the url stub because we do not need to care about the url being passed inside the URLProtocol
//            guard let url = request.url else {
//                return false
//            }
//
//            return stubs[url] != nil
            
            // Invoke the observer and pass the request (for testing URL purpose)
            
            
            //** This request observer is causing the URLProtocol to finish even before the process is done
            //** Thus causing the data races when the thread sanitizer is turned on
            //** SO, we move this line to the startLoading() method
//            requestObserver?(request)
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            //** This is added to fix the data races problem when running tests with thread sanitizer
            //** it makes sure that every request finished before the test methods that uses URLProtocol stub returns
            //** So we don't have running background threads concurrently with other test methods
            if let requestObserver = URLProtocolStub.requestObserver {
                client?.urlProtocolDidFinishLoading(self)
                return requestObserver(request)
            }
            
            guard let stub = URLProtocolStub.stub else {
                return
            }
            
            // If data is available, then we call the load data
            if let data = stub.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            // If response is available, then we call the didReceive response
            if let response = stub.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            // If error is available, then we call the client's method for failing with error
            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            // Always call this method because we need to always finish loading the request
            client?.urlProtocolDidFinishLoading(self)
        }
        
        // We need to implement this because otherwise it will cause a crash at runtime
        // But we don't have anything to put inside this method
        override func stopLoading() {
            
        }
    }
    
//    // We use this fake class because we don't actually want to hit the real url endpoint
//    // But when we start mocking classes we don't own, it can become dangerous
//    // Because these classes often have a bunch of methods that we don't override, and overriding the behavior can also be dangerous
//    private class FakeURLSessionDataTask: HTTPURLSessionDataTask {
//        // This needs to be added because it causes a crash, because we're using the resume method in the production code
//        // And this is not the best practice for tests
//        // This shows that mocking/subclassing this kind of class that we don't own is very fragile
//        func resume() {
//
//        }
//    }
//
//    // We need this spy for the 'test_getFromURL_resumesDataTaskWithURL'
//    // We do not use the fake one because this one needs to be a spy
//    private class URLSessionDataTaskSpy: HTTPURLSessionDataTask {
//        var resumesCallCount: Int = 0
//
//        func resume() {
//            resumesCallCount += 1
//        }
//    }
}
