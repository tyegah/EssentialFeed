//
//  URLSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by Ty Septiani on 20/09/22.
//

import Foundation

public class URLSessionHTTPClient:HTTPClient {
    private let session: URLSession
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    private struct UnexpectedValuesRepresentation:Error {}
    
    public func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            }
            // This data.count > 0 is an additional condition because it turns out that the URLProtocol/URLSession
            // Will return 0 bytes of data even if on the test we set the data to nil.
            // This is affecting the 'test_getFromURL_failsOnAllInvalidRepresentationCases' and cause it to fail
            // That's why we add this condition to make it pass
//            else if let data = data, data.count > 0, let response = response as? HTTPURLResponse {
//                completion(.success((data, response)))
//            }
            
            // This is how it is after we add one more test to handle the nil data that turns out to be empty data on URL loading system
            // No more data.count needed
            else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success((data, response)))
            }
            else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }.resume()
    }
}
