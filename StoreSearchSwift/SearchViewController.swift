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
    
    let search = Search()
    
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
    
    func showNetworkError() {
        let alert = UIAlertController(title: "Whoops...", message: "There was an error reading from the iTunes Store. Please try again.", preferredStyle: .Alert)
        
        let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alert.addAction(action)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func segmentChanged(sender: UISegmentedControl) {
        performSearch()
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowDetail" {
            switch search.state {
            case .Results(let list):
                let detailViewController = segue.destinationViewController as DetailViewController
                let indexPath = sender as NSIndexPath
                let searchResult = list[indexPath.row]
                detailViewController.searchResult = searchResult
            default:
                break
            }
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
            controller.search = search
            
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
        
        if let category = Search.Category(rawValue: segmentedControl.selectedSegmentIndex) {
            search.performSearchForText(searchBar.text, category: category,
                completion: { success in
                    if !success {
                        self.showNetworkError()
                    }
                    self.tableView.reloadData()
            })
        }
        
        
        
        tableView.reloadData()
        searchBar.resignFirstResponder()
    }
    
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }
}

extension SearchViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch search.state {
        case .NotSearchedYet: return 0
        case .Loading: return 1
        case .NoResults: return 1
        case .Results(let list): return list.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
        //You added an if-statement to return an instance of the new Loading... cell. It also looks up the UIActivityIndicatorView by its tag and then tells the spinner to start animating. The rest of the method stays the same.
        
        switch search.state {
        case .NotSearchedYet:
            fatalError("Should never get here")
        case .Loading:
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifiers.loadingCell, forIndexPath: indexPath) as UITableViewCell
            let spinner = cell.viewWithTag(100) as UIActivityIndicatorView
            spinner.startAnimating()
            
            return cell
            
        case .NoResults:
            return tableView.dequeueReusableCellWithIdentifier(
            TableViewCellIdentifiers.nothingFoundCell, forIndexPath: indexPath) as UITableViewCell
            
        case .Results(let list):
            let cell = tableView.dequeueReusableCellWithIdentifier(
                TableViewCellIdentifiers.searchResultCell, forIndexPath: indexPath) as SearchResultCell
            
            let searchResult = list[indexPath.row]
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
        switch search.state {
        case .NotSearchedYet, .Loading, .NoResults:
            return nil
        case .Results:
            return indexPath
        }
    }
}

extension SearchViewController: UITableViewDelegate {
    
}


