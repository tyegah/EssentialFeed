//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Ty Septiani on 16/09/22.
//

import Foundation


public typealias HTTPClientResult = Swift.Result<(Data, HTTPURLResponse), Error>

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}
