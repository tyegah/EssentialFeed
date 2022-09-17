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

class URLSessionHTTPClient {
    private let session: HTTPURLSession
    init(session: HTTPURLSession) {
        self.session = session
    }
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { _, _, error in
            if let error = error {
                completion(.failure(error))
            }
        }.resume()
    }
}

protocol HTTPURLSession {
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPURLSessionDataTask
}

protocol HTTPURLSessionDataTask {
    func resume()
}

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
    
    func test_getFromURL_resumesDataTaskWithURL() {
        // ARRANGE
        let url = URL(string: "https://a-url.com")!
        // Here we're using subclass-based mocking which would be
        // URLSessionSpy
        let session = URLSessionSpy()
        let task = URLSessionDataTaskSpy()
        // stubbing behavior
        session.stub(url: url, task: task)
        let sut = URLSessionHTTPClient(session: session)
        sut.get(from: url) { _ in }
        XCTAssertEqual(task.resumesCallCount, 1)
    }
    
    func test_getFromURL_failsOnRequestError() {
        // ARRANGE
        let url = URL(string: "https://a-url.com")!
        let error = NSError(domain: "", code: 0)
        // Here we're using subclass-based mocking which would be
        // URLSessionSpy
        let session = URLSessionSpy()
        // stubbing behavior
        session.stub(url: url, error: error)
        let sut = URLSessionHTTPClient(session: session)
        
        // Here we start to need to see the result for the error
        // So we change the production code which is the get(from:URL) method
        // To have completion handler to get the result
        let exp = expectation(description: "Wait for result")
        sut.get(from: url) { result in
            switch result {
            case let .failure(err as NSError):
                XCTAssertEqual(error, err)
            default:
                XCTFail("Expected failure, got \(result) instead")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    // MARK: Helpers
    private class URLSessionSpy: HTTPURLSession {
        // we remove this because it's no longer needed, because the 1st test is removed
//        var requestedURLs = [URL]()
        var stubs = [URL: Stub]()
        
        struct Stub {
            let task: HTTPURLSessionDataTask
            let error:Error?
        }
        
        func stub(url: URL, task: HTTPURLSessionDataTask = FakeURLSessionDataTask(), error: Error? = nil) {
            self.stubs[url] = Stub(task: task, error: error)
        }
  
        func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPURLSessionDataTask {
//            requestedURLs.append(url)
            // We return the stubbed data task, and if it's not available for the given url
            // we return the fake one as the default
//            return stubs[url] ?? FakeURLSessionDataTask()
            
            // Now we're adding error into the stub, we add Stub object/struct a helper
            guard let stub = stubs[url] else {
                fatalError("Couldn't find the task for the url \(url)")
            }
            completionHandler(nil, nil, stub.error)
            return stub.task
        }
    }
    
    // We use this fake class because we don't actually want to hit the real url endpoint
    // But when we start mocking classes we don't own, it can become dangerous
    // Because these classes often have a bunch of methods that we don't override, and overriding the behavior can also be dangerous
    private class FakeURLSessionDataTask: HTTPURLSessionDataTask {
        // This needs to be added because it causes a crash, because we're using the resume method in the production code
        // And this is not the best practice for tests
        // This shows that mocking/subclassing this kind of class that we don't own is very fragile
        func resume() {
            
        }
    }
    
    // We need this spy for the 'test_getFromURL_resumesDataTaskWithURL'
    // We do not use the fake one because this one needs to be a spy
    private class URLSessionDataTaskSpy: HTTPURLSessionDataTask {
        var resumesCallCount: Int = 0
        
        func resume() {
            resumesCallCount += 1
        }
    }
}
