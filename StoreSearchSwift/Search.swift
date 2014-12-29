//
//  Search.swift
//  StoreSearchSwift
//
//  Created by Iino, Daisuke | Dai | BASD on 12/26/14.
//  Copyright (c) 2014 Iino Daisuke. All rights reserved.
//

import UIKit
import Foundation

//The typealias statement allows you to create a more convenient name for a data type, in order to save some keystrokes and to make the code more readable.
//Here you’re declaring a type for your own closure, named SearchComplete. This is a closure that returns no value (it is Void) and takes one parameter, a Bool. If you think this syntax is weird, then I’m right there with you, but that’s the way it is.
//From now on you can use the name SearchComplete to refer to a closure that takes one Bool parameter and returns no value.
typealias SearchComplete = (Bool) -> Void

class Search {

    enum State {
        case NotSearchedYet
        case Loading
        case NoResults
        case Results([SearchResult])
    }
    
    private(set) var state: State = .NotSearchedYet
    private var dataTask: NSURLSessionDataTask? = nil
    
    enum Category: Int {
        case All = 0
        case Music = 1
        case Software = 2
        case EBook = 3
        
        var entityName: String {
            switch self {
                case .All: return ""
                case .Music: return "musicTrack"
                case .Software: return "software"
                case .EBook: return "ebook"
            }
        }
    }
    
    func performSearchForText(text: String, category: Category, completion: SearchComplete) {
        
        if !text.isEmpty {
            
            dataTask?.cancel()
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            
            //Before you do the networking request, you set isLoading to true and reload the table to show the activity indicator.
            state = .Loading
            
            //Create the NSURL object with the search text like before.
            let url = self.urlWithSearchText(text, category: category)
            
            //Obtain the NSURLSession object. This grabs the “shared” session, which always exists and uses a default configuration with respect to caching, cookies, and other web stuff.
            let session = NSURLSession.sharedSession()
            
            //Create a data task. Data tasks are for sending HTTP GET requests to the server at url. The code from the completion handler will be invoked when the data task has received the reply from the server.
            dataTask = session.dataTaskWithURL(url, completionHandler: {
                data, response, error in
                //Inside the closure you’re given three parameters: data, response, and error. These are all ! optionals so they can nil, but you don’t have to unwrap them.
                //If there was a problem, error contains an NSError object describing what went wrong. This happens when the server cannot be reached or the network is down or some other hardware failure.
                //If error is nil, the communication with the server succeeded; response holds the server’s response code and headers, and data contains the actual thing that was sent back from the server, in this case a blob of JSON.
                
                self.state = .NotSearchedYet
                var success = false
                
                if let error = error {
                    println("Failure! \(error)")
                    if error.code == -999 { return }
                } else if let httpResponse = response as? NSHTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        if let dictionary = self.parseJSON(data) {
                            var searchResults = self.parseDictionary(dictionary)
                            if searchResults.isEmpty {
                                self.state = .NoResults
                            } else {
                                searchResults.sort(<)
                                self.state = .Results(searchResults)
                            }
                            success = true
                        }
                    }
                }
                
                dispatch_async(dispatch_get_main_queue()){
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    completion(success)
                }
            })
            //Finally, once you have created the data task, you need to call resume() to start it. This sends the request to the server. That all happens on a background thread, so the app is immediately free to continue (NSURLSession is as asynchronous as they come).
            dataTask?.resume()
            
        }

    }

    private func urlWithSearchText(searchText: String, category: Category) -> NSURL {
        let entityName = category.entityName
        let escapedSearchText =
        searchText.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        
        let urlString = String(format:
            "http://itunes.apple.com/jp/search?term=%@&limit=200&entity=%@", escapedSearchText, entityName)
        let url = NSURL(string: urlString)
        return url!
        
    }
    
    
    private func parseJSON(data: NSData) -> [String: AnyObject]? {
        var error: NSError?
        if let json = NSJSONSerialization.JSONObjectWithData(data,
            options: NSJSONReadingOptions(0), error: &error) as? [String: AnyObject] {
                return json
        } else if let error = error {
            println("JSON Error: \(error)")
        } else {
            println("Unknown JSON Error")
        }
        return nil
    }
    
    private func parseDictionary(dictionary: [String: AnyObject]) -> [SearchResult] {
        //You’re making the method return an array of SearchResult objects. (If something went wrong during parsing, it simply returns an empty array.)
        var searchResults = [SearchResult]()
        
        //First there is a bit of defensive programming to make sure the dictionary has a key named results that contains an array. It probably will, but better safe than sorry.
        if let array: AnyObject = dictionary["results"] {
            //Once it is satisfied that array exists, the method uses a for-loop to look at each of the array’s elements in turn.
            for resultDict in array as [AnyObject] {
                //Each of the elements from the array is another dictionary. Because you’re dealing with an Objective-C API here, you don’t actually receive nice Dictionary and Array objects, but objects of type AnyObject. (Recall that AnyObject exists to make Swift compatible with Objective-C and the iOS frameworks.)
                //To make sure these objects really do represent a dictionary, you have to cast them to the right type first. You’re using the optional cast as? here as another defensive measure. In theory it’s possible resultDict doesn’t actually hold a [String: AnyObject] dictionary and then you don’t want to continue.
                if let resultDict = resultDict as? [String: AnyObject] {
                    //For each of the dictionaries, you print out the value of its wrapperType and kind fields. Indexing a dictionary always gives you an optional, which is why you’re using if let, but you also cast to NSString. That is the Objective-C string type and it is interchangeable with Swift’s String (these types are “bridged” so you can use NSString wherever you can use String, and vice versa). In certain cases you do need to explicitly use NSString, and this is one of them.
                    
                    var searchResult: SearchResult?
                    
                    //If the found item is a “track” then you create a SearchResult object for it, using a new method parseTrack(), and add it to the searchResults array.
                    if let wrapperType = resultDict["wrapperType"] as? NSString {
                        switch wrapperType {
                        case "track":
                            searchResult = parseTrack(resultDict)
                        case "audiobook":
                            searchResult = parseAudioBook(resultDict)
                        case "software":
                            searchResult = parseSoftware(resultDict)
                        default:
                            break
                        }
                        //For some reason, e-books do not have a wrapperType field, so in order to determine whether something is an e-book you have to look at the kind field instead.
                    } else if let kind = resultDict["kind"] as? NSString {
                        if kind == "ebook" {
                            searchResult = parseEBook(resultDict)
                        }
                    }
                    //For any other types of products, the temporary variable searchResult remains nil and doesn’t get added to the array (that’s why it’s an optional).
                    if let result = searchResult {
                        searchResults.append(result)
                    }
                    
                } else {
                    //If something went wrong, print out an error message. That’s always useful for debugging.
                    println("Error: Expected a dictionary")
                }
            }// for loop
        } else {
            println("Error: Expected `results` array")
        }
        return searchResults
    }
    
    private func parseTrack(dictionary: [String: AnyObject]) -> SearchResult {
        let searchResult = SearchResult()
        
        searchResult.name = dictionary["trackName"] as NSString
        searchResult.artistName = dictionary["artistName"] as NSString
        searchResult.artworkURL60 = dictionary["artworkUrl60"] as NSString
        searchResult.artworkURL100 = dictionary["artworkUrl100"] as NSString
        searchResult.storeURL = dictionary["trackViewUrl"] as NSString
        searchResult.kind = dictionary["kind"] as NSString
        searchResult.currency = dictionary["currency"] as NSString
        
        if let price = dictionary["trackPrice"] as? NSNumber {
            searchResult.price = Double(price)
        }
        if let genre = dictionary["primaryGenreName"] as? NSString {
            searchResult.genre = genre
        }
        
        return searchResult
    }
    
    private func parseAudioBook(dictionary: [String: AnyObject]) -> SearchResult {
        let searchResult = SearchResult()
        
        searchResult.name = dictionary["collectionName"] as NSString
        searchResult.artistName = dictionary["artistName"] as NSString
        searchResult.artworkURL60 = dictionary["artworkUrl60"] as NSString
        searchResult.artworkURL100 = dictionary["artworkUrl100"] as NSString
        searchResult.storeURL = dictionary["collectionViewUrl"] as NSString
        //Audio books don’t have a “kind” field, so you have to set the kind property to "audiobook" yourself.
        searchResult.kind = "audiobook"
        searchResult.currency = dictionary["currency"] as NSString
        
        if let price = dictionary["collectionPrice"] as? NSNumber {
            searchResult.price = Double(price)
        }
        if let genre = dictionary["primaryGenreName"] as? NSString {
            searchResult.genre = genre
        }
        
        return searchResult
    }
    
    private func parseSoftware(dictionary: [String: AnyObject]) -> SearchResult {
        let searchResult = SearchResult()
        
        searchResult.name = dictionary["trackName"] as NSString
        searchResult.artistName = dictionary["artistName"] as NSString
        searchResult.artworkURL60 = dictionary["artworkUrl60"] as NSString
        searchResult.artworkURL100 = dictionary["artworkUrl100"] as NSString
        searchResult.storeURL = dictionary["trackViewUrl"] as NSString
        searchResult.kind = dictionary["kind"] as NSString
        searchResult.currency = dictionary["currency"] as NSString
        
        if let price = dictionary["price"] as? NSNumber {
            searchResult.price = Double(price)
        }
        if let genre = dictionary["primaryGenreName"] as? NSString {
            searchResult.genre = genre
        }
        
        return searchResult
    }
    
    private func parseEBook(dictionary: [String: AnyObject]) -> SearchResult {
        let searchResult = SearchResult()
        
        searchResult.name = dictionary["trackName"] as NSString
        searchResult.artistName = dictionary["artistName"] as NSString
        searchResult.artworkURL60 = dictionary["artworkUrl60"] as NSString
        searchResult.artworkURL100 = dictionary["artworkUrl100"] as NSString
        searchResult.storeURL = dictionary["trackViewUrl"] as NSString
        searchResult.kind = dictionary["kind"] as NSString
        searchResult.currency = dictionary["currency"] as NSString
        
        if let price = dictionary["price"] as? NSNumber {
            searchResult.price = Double(price)
        }
        
        //E-books don’t have a “primaryGenreName” field, but an array of genres. You use the join() method to glue these genre names into a single string, separated by commas. (Yep, you’re calling join() on a string literal, cool huh!)
        if let genres: AnyObject = dictionary["genres"] {
            searchResult.genre = ", ".join(genres as [String])
        }
        
        return searchResult
    }


}