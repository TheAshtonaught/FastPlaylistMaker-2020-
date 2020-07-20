//
//  ApiConvience.swift
//  Fast Playist Maker
//

import Foundation

class ApiConvenience {
    
    var session: URLSession! = nil
    var apiConstants = ApiConstants()
    
    init(apiConstants: ApiConstants) {
        newSession(apiConstants: apiConstants)
    }
    
    func newSession(apiConstants: ApiConstants) {
        self.session = URLSession(configuration: URLSessionConfiguration.default)
        self.apiConstants.scheme = apiConstants.scheme
        self.apiConstants.host = apiConstants.host
        self.apiConstants.path = apiConstants.path
        self.apiConstants.domain = apiConstants.domain
    }
    
    func apiUrlForMethod(method: String?, PathExt: String? = nil, parameters: [String:AnyObject]? = nil) -> NSURL {
        
        let components = NSURLComponents()
        components.scheme = apiConstants.scheme
        components.host = apiConstants.host
        components.path = apiConstants.path + (method ?? "") + (PathExt ?? "")
        
        if let parameters = parameters {
            components.queryItems = [NSURLQueryItem]() as [URLQueryItem]?
            for (key, value) in parameters {
                let queryItem = NSURLQueryItem(name: key, value: "\(value)")
                components.queryItems!.append(queryItem as URLQueryItem)
            }
        }
        return components.url! as NSURL
    }
    
    func apiRequest(url: NSURL, method: String, _ headers: [String: String]?, completionHandler: @escaping (Data?, NSError?) -> Void) {
        
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = method
        
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
            
        }
        
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            if let error = error {
                completionHandler(nil, error as NSError?)
                return
            }
            
            if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                if (statusCode < 200 && statusCode > 299) {
                    let userInfo = [
                        NSLocalizedDescriptionKey: "Bad Response"
                    ]
                    let error = NSError(domain: "API", code: statusCode, userInfo: userInfo)
                    completionHandler(nil, error)
                    return
                }
            }
            completionHandler(data, nil)
        }
        task.resume()
    }
    
    func apiRequest(withJsonBody body: [String: AnyObject], url: NSURL, method: String, _ headers: [String: String]?, completionHandler: @escaping (Data?, NSError?) -> Void) {
        
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = method
        
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
            
        }
        
        let jsonObject: NSMutableDictionary = NSMutableDictionary()
        
        for (key, value) in body {
            jsonObject.setValue(value, forKey: key)
        }
//        jsonObject.setValue(value1, forKey: "b")
        
        
//        let jsonData: NSData
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: JSONSerialization.WritingOptions())
            request.httpBody = jsonData
            
        } catch _ {
            print ("JSON Failure")
        }
        
//        let json = body
//        
//        if let jsonData = try? JSONSerialization.data(withJSONObject: json) {
//            request.httpBody = jsonData
//        } else {
//            print("json body error")
//            return
//        }
        
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            if let error = error {
                completionHandler(nil, error as NSError?)
                return
            }
            
            if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                if (statusCode < 200 && statusCode > 299) {
                    let userInfo = [
                        NSLocalizedDescriptionKey: "Bad Response"
                    ]
                    let error = NSError(domain: "API", code: statusCode, userInfo: userInfo)
                    completionHandler(nil, error)
                    return
                }
            }
            completionHandler(data, nil)
        }
        task.resume()
    }
    
    
    func dropAllTask(apiConstants: ApiConstants) {
        session.invalidateAndCancel()
        newSession(apiConstants: apiConstants)
    }
    
    // helper function to return errors
    
    func errorReturn(code: Int, description: String, domain: String)-> NSError {
        let userInfo = [NSLocalizedDescriptionKey: description]
        return NSError(domain: domain, code: code, userInfo: userInfo)
    }
}


extension ApiConvenience {
    
    func buildSpotifyTokenRequestUrl(method: String?, PathExt: String? = nil, parameters: [String:AnyObject]? = nil) -> NSURL {
        
        let components = NSURLComponents()
        components.scheme = "https"
        components.host = "accounts.spotify.com"
        components.path = "/api/token" + (method ?? "") + (PathExt ?? "")
        
        if let parameters = parameters {
            components.queryItems = [NSURLQueryItem]() as [URLQueryItem]?
            for (key, value) in parameters {
                let queryItem = NSURLQueryItem(name: key, value: "\(value)")
                components.queryItems!.append(queryItem as URLQueryItem)
            }
        }
        return components.url! as NSURL
    }
    
}
