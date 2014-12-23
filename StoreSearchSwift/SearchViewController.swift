//
//  ViewController.swift
//  StoreSearchSwift
//
//  Created by Iino Daisuke on 2014/11/26.
//  Copyright (c) 2014年 Iino Daisuke. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    var landscapeViewController: LandscapeViewController?
    
    
    var searchResults = [SearchResult]()
    var hasSearched = false
    var isLoading = false
    
    var dataTask: NSURLSessionDataTask?
    
    struct TableViewCellIdentifiers {
        static let searchResultCell = "SearchResultCell"
        static let nothingFoundCell = "NothingFoundCell"
        static let loadingCell = "LoadingCell"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        //This tells the table view to add a 108-point margin at the top, made up of 20 points for the status bar and 44 points for the Search Bar.
        tableView.contentInset = UIEdgeInsets(top: 108, left: 0, bottom: 0, right: 0)
        
        //The UINib class is used to load nibs. Here you tell it to load the nib you just created (note that you don’t specify the .xib file extension). Then you ask the table view to register this nib for the reuse identifier “SearchResultCell”.
        //From now on, when you call dequeueReusableCellWithIdentifier() for the identifier “SearchResultCell”, UITableView will automatically make a new cell from the nib – or reuse an existing cell if one is available, of course. And that’s all you need to do.
        var cellNib = UINib(nibName: TableViewCellIdentifiers.searchResultCell, bundle: nil)
        tableView.registerNib(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.searchResultCell)
        cellNib = UINib(nibName: TableViewCellIdentifiers.nothingFoundCell, bundle: nil)
        tableView.registerNib(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.nothingFoundCell)
        cellNib = UINib(nibName: TableViewCellIdentifiers.loadingCell, bundle: nil)
        tableView.registerNib(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.loadingCell)
        
        tableView.rowHeight = 80
        
        searchBar.becomeFirstResponder()
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func urlWithSearchText(searchText: String, category: Int) -> NSURL {
        var entityName: String
        switch category {
            case 1: entityName = "musicTrack"
            case 2: entityName = "software"
            case 3: entityName = "ebook"
            default: entityName = ""
        }
        
        let escapedSearchText =
            searchText.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        
        let urlString = String(format:
            "http://itunes.apple.com/jp/search?term=%@&limit=200&entity=%@", escapedSearchText, entityName)
        let url = NSURL(string: urlString)
        return url!
        
    }
    
    
    func parseJSON(data: NSData) -> [String: AnyObject]? {
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
    
    func showNetworkError() {
        let alert = UIAlertController(title: "Whoops...", message: "There was an error reading from the iTunes Store. Please try again.", preferredStyle: .Alert)
        
        let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alert.addAction(action)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func parseDictionary(dictionary: [String: AnyObject]) -> [SearchResult] {
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
    
    func parseTrack(dictionary: [String: AnyObject]) -> SearchResult {
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
    
    func parseAudioBook(dictionary: [String: AnyObject]) -> SearchResult {
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
    
    func parseSoftware(dictionary: [String: AnyObject]) -> SearchResult {
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
    
    func parseEBook(dictionary: [String: AnyObject]) -> SearchResult {
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
    
    @IBAction func segmentChanged(sender: UISegmentedControl) {
        performSearch()
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowDetail" {
            let detailViewController = segue.destinationViewController as DetailViewController
            let indexPath = sender as NSIndexPath
            let searchResult = searchResults[indexPath.row]
            detailViewController.searchResult = searchResult
        }
    }
    
    /*
    This method isn’t just invoked on device rotations but any time the trait collection for the view controller changes. So what is a trait collection? It is, um, a collection of traits, where a trait can be:
    
    - the horizontal size class
    - the vertical size class
    - the display scale (is this a Retina screen or not?)
    - the user interface idiom (is this an iPhone or iPad?)
    
    Whenever one or more of these traits change, for whatever reason, UIKit calls willTransitionToTraitCollection(withTransitionCoordinator) to give the view controller a chance to adapt to the new traits.
    
    When an iPhone app is in portrait orientation, the horizontal size class is Compact and the vertical size class is Regular.
    Upon a rotation to landscape, the vertical size class changes to Compact.
    What you may not have expected is that the horizontal size class doesn’t change and stays Compact in both portrait and landscape orientations – except on the iPhone 6 Plus, that is. In landscape, the horizontal size class on the 6 Plus is Regular. That’s because the larger dimensions of the iPhone 6 Plus can fit a split screen in landscape mode, like the iPad (something you’ll see later on).
    What this boils down to is that to detect an iPhone rotation, you just have to look at how the vertical size class changed. That’s exactly what the switch statement does.
    
    If the new vertical size class is .Compact the device got flipped to landscape and you show the LandscapeViewController. But if the new size class is .Regular, the app is back in portrait and you hide the landscape view again.
    */
    
    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
        
        switch newCollection.verticalSizeClass {
        case .Compact:
            showLandscapeViewWithCoordintor(coordinator)
        case .Regular, .Unspecified:
            hideLandscapeViewWithCoordinator(coordinator)
        }
    }

    
    
    func showLandscapeViewWithCoordintor(coordinator: UIViewControllerTransitionCoordinator) {
        /*
        It should never happen that the app instantiates a second landscape view when you’re already looking at one. The pre-condition that landscapeViewController is still nil codifies this requirement and drops the app into the debugger if it turns out that this condition doesn’t hold.
        If the assumptions that your code makes aren’t valid, you definitely want to find out about them during testing; precondition() and assert() are how you document and test for these assumptions. (The difference is that asserts are disabled in the final App Store build of the app but preconditions aren’t.)
        */
        precondition(landscapeViewController == nil)
        /*
        Find the scene with the ID “LandscapeViewController” in the storyboard and instantiate it. Because you don’t have a segue you need to do this manually.
        The landscapeViewController instance variable is an optional so you need to unwrap it before you can continue.
        */
        landscapeViewController = storyboard!.instantiateViewControllerWithIdentifier("LandscapeViewController") as? LandscapeViewController
        
        if let controller = landscapeViewController {
            //Set the size and position of the new view controller. This makes the landscape view just as big as the SearchViewController, covering the entire screen.
            //The frame is the rectangle that describes the view’s position and size in terms of its superview. To move a view to its final position and size you usually set its frame. The bounds is also a rectangle but seen from the inside of the view.
            //Because SearchViewController’s view is the superview here, the frame of the landscape view must be made equal to the SearchViewController’s bounds.
            controller.view.frame = view.bounds
            //the landscape view starts out completely see-through (alpha = 0) and slowly fades in while the rotation takes place until it’s fully visible (alpha = 1).
            controller.view.alpha = 0
            //First, add the landscape controller’s view as a subview. This places it on top of the table view, search bar and segmented control.
            view.addSubview(controller.view)
            //Then tell the SearchViewController that the LandscapeViewController is now managing that part of the screen, using addChildViewController(). If you forget this step then the new view controller may not always work correctly.
            addChildViewController(controller)
            //Tell the new view controller that it now has a parent view controller with didMoveToParentViewController().
            
            //The call to animateAlongsideTransition() takes two closures: the first is for the animation itself, the second is a “completion handler” that gets called after the animation finishes. The completion handler gives you a chance to delay the call to didMoveToParentViewController() until the animation is over.
            coordinator.animateAlongsideTransition({ _ in
                controller.view.alpha = 1
                self.searchBar.resignFirstResponder()
                if self.presentedViewController != nil {
                    self.dismissViewControllerAnimated(true , completion: nil)
                }
            },
            completion:{ _ in
                controller.didMoveToParentViewController(self)
            })
            //controller.didMoveToParentViewController(self)
        }
    }
    
    func hideLandscapeViewWithCoordinator(coordinator: UIViewControllerTransitionCoordinator) {
        if let controller = landscapeViewController {
            //First you call willMoveToParentViewController() to tell the view controller that it is leaving the view controller hierarchy (it no longer has a parent), then you remove its view from the screen, and finally you call removeFromParentViewController() to truly dispose of the view controller.
            controller.willMoveToParentViewController(nil)
            
            coordinator.animateAlongsideTransition({ _ in
                controller.view.alpha = 0
            }, completion: { _ in
                controller.view.removeFromSuperview()
                controller.removeFromParentViewController()
                self.landscapeViewController = nil
            })
        }
    }

}

extension SearchViewController: UISearchBarDelegate {

    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        performSearch()
    }
    
    func performSearch() {
       
        if !searchBar.text.isEmpty {
            
            searchBar.resignFirstResponder()
            dataTask?.cancel()
            
            //Before you do the networking request, you set isLoading to true and reload the table to show the activity indicator.
            isLoading = true
            tableView.reloadData()
            
            hasSearched = true
            searchResults = [SearchResult]()
            
            //Create the NSURL object with the search text like before.
            let url = self.urlWithSearchText(searchBar.text, category: segmentedControl.selectedSegmentIndex)
            
            //Obtain the NSURLSession object. This grabs the “shared” session, which always exists and uses a default configuration with respect to caching, cookies, and other web stuff.
            let session = NSURLSession.sharedSession()
            
            //Create a data task. Data tasks are for sending HTTP GET requests to the server at url. The code from the completion handler will be invoked when the data task has received the reply from the server.
            dataTask = session.dataTaskWithURL(url, completionHandler: {
                data, response, error in
                //Inside the closure you’re given three parameters: data, response, and error. These are all ! optionals so they can nil, but you don’t have to unwrap them.
                //If there was a problem, error contains an NSError object describing what went wrong. This happens when the server cannot be reached or the network is down or some other hardware failure.
                //If error is nil, the communication with the server succeeded; response holds the server’s response code and headers, and data contains the actual thing that was sent back from the server, in this case a blob of JSON.
                if let error = error {
                    println("Failure! \(error)")
                    if error.code == -999 { return }
                } else if let httpResponse = response as? NSHTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        if let dictionary = self.parseJSON(data) {
                            self.searchResults = self.parseDictionary(dictionary)
                            self.searchResults.sort(<)
                            
                            dispatch_async(dispatch_get_main_queue()) {
                                self.isLoading = false
                                self.tableView.reloadData()
                            }
                            return
                        }
                    
                    } else {
                        println("Failure! \(response)")
                    }
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.hasSearched = false
                    self.isLoading = false
                    self.tableView.reloadData()
                    self.showNetworkError()
                }
            })
            //Finally, once you have created the data task, you need to call resume() to start it. This sends the request to the server. That all happens on a background thread, so the app is immediately free to continue (NSURLSession is as asynchronous as they come).
            dataTask?.resume()
            
        }
    }
    
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }
}

extension SearchViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isLoading {
            return 1
        } else if !hasSearched {
            return 0
        } else if searchResults.count == 0 {
            return 1
        } else {
            return searchResults.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
        //You added an if-statement to return an instance of the new Loading... cell. It also looks up the UIActivityIndicatorView by its tag and then tells the spinner to start animating. The rest of the method stays the same.
        if isLoading {
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifiers.loadingCell, forIndexPath: indexPath) as UITableViewCell
            let spinner = cell.viewWithTag(100) as UIActivityIndicatorView
            spinner.startAnimating()
            
            return cell
            
        } else if searchResults.count == 0 {
           return tableView.dequeueReusableCellWithIdentifier(
            TableViewCellIdentifiers.nothingFoundCell, forIndexPath: indexPath) as UITableViewCell
            
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(
                TableViewCellIdentifiers.searchResultCell, forIndexPath: indexPath) as SearchResultCell
            
            let searchResult = searchResults[indexPath.row]
            cell.configureForSearchResult(searchResult)
            return cell
        }
    }
    
    //The tableView(didSelectRowAtIndexPath) method will simply deselect the row with an animation
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        performSegueWithIdentifier("ShowDetail", sender: indexPath)
        
    }
    
    // The willSelectRowAtIndexPath makes sure that you can only select rows with actual search results
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if searchResults.count == 0 || isLoading {
            return nil
        } else {
            return indexPath
        }
    }
}

extension SearchViewController: UITableViewDelegate {
    
}


