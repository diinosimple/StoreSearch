//
//  LandscapeViewController.swift
//  StoreSearchSwift
//
//  Created by Iino Daisuke on 2014/12/21.
//  Copyright (c) 2014年 Iino Daisuke. All rights reserved.
//

import UIKit

class LandscapeViewController: UIViewController {
    
    @IBOutlet weak var scrollView:  UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    var search: Search!
    
    //You are declaring this instance variable as private. firstTime is an internal piece of state that only LandscapeViewController cares about. It should not be visible to other objects.
    private var firstTime = true;
    
    private var downloadTasks = [NSURLSessionDownloadTask]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        pageControl.numberOfPages = 0
        
        //Remember how, if you don’t add make constraints of your own, Interface Builder will give the views automatic constraints? Well, those automatic constraints get in the way if you’re going to do your own layout. That’s why you need to remove these unwanted constraints from the main view, pageControl, and scrollView first.
        view.removeConstraints(view.constraints())
        view.setTranslatesAutoresizingMaskIntoConstraints(true)
        
        //You also call setTranslatesAutoresizingMaskIntoConstraints(true). That allows you to position and size your views manually by changing their frame property.
        //When Auto Layout is enabled, you’re not supposed to change the frame yourself – you can only indirectly move views into position by creating constraints. Modifying the frame by hand will cause conflicts with the existing constraints and bring all sorts of trouble (you don’t want to make Auto Layout angry!).
        //For this view controller it’s much more convenient to manipulate the frame property directly than it is making constraints (especially when you’re placing the buttons for the search results), which is why you’re disabling Auto Layout.
        
        pageControl.removeConstraints(pageControl.constraints())
        pageControl.setTranslatesAutoresizingMaskIntoConstraints(true)
        
        scrollView.removeConstraints(scrollView.constraints())
        scrollView.setTranslatesAutoresizingMaskIntoConstraints(true)
        
        //Now that Auto Layout is out of the way, you can do your own layout. That happens in the method viewWillLayoutSubviews().
        
        //An image? But you’re setting the backgroundColor property, which is a UIColor, not a UIImage?! Yup, that’s true, but UIColor has a cool trick that lets you use a tile- able image for a color.
        //If you take a peek at the LandscapeBackground image in the asset catalog you’ll see that it is a small square. By setting this image as a pattern image on the background you get a repeatable image that fills the whole screen. You can use tile- able images anywhere you can use a UIColor.
        scrollView.backgroundColor = UIColor(patternImage: UIImage(named: "LandscapeBackground")!)
        
        //It is very important when dealing with scroll views that you set the contentSize property. This tells the scroll view how big its insides are. You don’t change the frame (or bounds) of the scroll view if you want its insides to be bigger, you set the contentSize property instead.
        //scrollView.contentSize = CGSize(width: 1000, height: 1000)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        scrollView.frame = view.bounds
        
        pageControl.frame = CGRect(
            x: 0,
            y: view.frame.size.height - pageControl.frame.size.height,
            width: view.frame.size.width,
            height: pageControl.frame.size.height)
        
        if firstTime {
            firstTime = false
            switch search.state {
            case .NotSearchedYet:
                break
            case .Loading:
                //println("loading")
                showSpinner()
                break
            case .NoResults:
                showNothingFoundLabel()
                break
            case .Results(let list):
                tileButtons(list)
            }
        }
        
    }
    
    //This programmatically creates a new UIActivityIndicatorView object (a big white one this time), puts it in the center of the screen, and starts animating it.
    //You give the spinner the tag 1000, so you can easily remove it from the screen once the search is done.
    private func showSpinner() {
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        spinner.center = CGPoint(x: CGRectGetMidX(scrollView.bounds) + 0.5,y: CGRectGetMidY(scrollView.bounds) + 0.5)
        spinner.tag = 1000
        view.addSubview(spinner)
        spinner.startAnimating()
    }
    
    func searchResultsReceived() {
        hideSpinner()
        
        switch search.state {
        case .NotSearchedYet, .Loading:
            break
        case .NoResults:
            showNothingFoundLabel()
        case .Results(let list):
            tileButtons(list)
        }
    }
    
    //The private hideSpinner() method looks for the view with tag 1000 – the activity spinner – and then tells that view to remove itself from the screen.
    private func hideSpinner() {
        view.viewWithTag(1000)?.removeFromSuperview()
    }
    
    
    private func showNothingFoundLabel() {
        //Here you first create a UILabel object and give it text and color. To make the label see-through the backgroundColor property is set to UIColor.clearColor().
        let label = UILabel(frame: CGRect.zeroRect)
        label.text = NSLocalizedString("Nothing found", comment: "label for Nothing found")
        label.backgroundColor = UIColor.clearColor()
        label.textColor = UIColor.whiteColor()
        
        //The call to sizeToFit() tells the label to resize itself to the optimal size. You could have given the label a frame that was big enough to begin with, but I find this just as easy. (It also helps when you’re translating the app to a different language, in which case you may not know beforehand how large the label needs to be.)
        label.sizeToFit()
        
        //The only trouble is that you want to center the label in the view and as you saw before that gets tricky when the width or height are odd (something you don’t necessarily know in advance). So here you use a little trick to always force the dimensions of the label to be even numbers:
        //width = ceil(width/2) * 2
        //If you divide a number such as 11 by 2 you get 5.5. The ceil() function rounds up 5.5 to make 6, and then you multiply by 2 to get a final value of 12. This formula always gives you the next even number if the original is odd. (You only need to do this because these values have type CGFloat. If they were integers, you wouldn’t have to worry about fractional parts.)
        var rect = label.frame
        rect.size.width = ceil(rect.size.width/2) * 2
        rect.size.height = ceil(rect.size.height/2) * 2
        label.frame = rect
        
        label.center = CGPoint(x: CGRectGetMidX(scrollView.bounds), y: CGRectGetMidY(scrollView.bounds))
        view.addSubview(label)
    }
    private func tileButtons(searchResults: [SearchResult]) {
        //First, the method must decide on how big the grid squares will be and how many squares you need to fill up each page. There are four cases to consider, based on the width of the screen:
        //480 points, 3.5-inch device (iPhone 4S). A single page fits 3 rows (rowsPerPage) of 5 columns (columnsPerPage). Each grid square is 96 by 88 points (itemWidth and itemHeight). The first row starts at Y = 20 (marginY).
        var columnsPerPage = 5
        var rowsPerPage = 3
        var itemWidth: CGFloat = 96
        var itemHeight: CGFloat = 88
        var marginX: CGFloat = 0
        var marginY: CGFloat = 20
        
        let scrollViewWidth = scrollView.bounds.size.width
        
        switch scrollViewWidth {
        case 568:
            //568 points, 4-inch device (all iPhone 5 models). This has 3 rows of 6 columns. To make it fit, each grid square is now only 94 points wide. Because 568 doesn’t evenly divide by 6, the marginX variable is used to adjust for the 4 points that are left over (2 on each side of the page).
            columnsPerPage = 6
            itemWidth = 94
            marginX = 2
        case 667:
            //667 points, 4.7-inch device (iPhone 6). This still has 3 rows but 7 columns. Because there’s some extra vertical space, the rows are higher (98 points) and there is a larger margin at the top.
            columnsPerPage = 7
            itemWidth = 95
            itemHeight = 98
            marginX = 1
            marginY = 29
        case 736:
            //736 points, 5.5-inch device (iPhone 6 Plus). This device is huge and can house 4 rows of 8 columns.
            columnsPerPage = 8
            rowsPerPage = 4
            itemWidth = 92
        default:
            break
            
        }
        
        let buttonWidth: CGFloat = 82
        let buttonHeight: CGFloat = 82
        let paddingHorz = (itemWidth - buttonWidth)/2
        let paddingVert = (itemHeight - buttonHeight)/2
        
        //Now you can loop through the array of search results and make a new button for each SearchResult object.
        
        var row = 0
        var column = 0
        var x = marginX
        
        //The for in loop steps through the SearchResult objects from the array, but with a twist. By doing for in enumerate(...), you get a tuple containing not only the next SearchResult object but also its index in the array. Recall that a tuple is nothing more than a temporary list with two or more items in it. This is a neat trick to loop through an array and get both the objects and their indices.
        for (index, searchResult) in enumerate(searchResults) {
            
            //Create the UIButton object. For debugging purposes you give each button a title with the array index. If there are 200 results in the search, you also should end up with 200 buttons. Setting the index on the button will help to verify this.
            let button = UIButton.buttonWithType(.Custom) as UIButton
            button.setBackgroundImage(UIImage(named: "LandscapeButton"), forState: .Normal)
            downloadImageForSearchResult(searchResult, andPlaceOnButton: button)
            
            //First you give the button a tag, so you know to which index in the .Results array this button corresponds. That’s needed in order to pass the correct SearchResult object to the Detail pop-up.
            button.tag = 2000 + index
            button.addTarget(self, action: Selector("buttonPressed:"), forControlEvents: .TouchUpInside)
            
            //When you make a button by hand you always have to set its frame. Using the measurements you figured out earlier, you determine the position and size of the button. Notice that CGRect’s fields all have the CGFloat type but row is an Int. You need to convert row to a CGFloat before you can use it in the calculation.
            button.frame = CGRect(
                x: x + paddingHorz,
                y: marginY + CGFloat(row)*itemHeight + paddingVert,
                width: buttonWidth, height: buttonHeight)
            
            //You add the new button object as a subview to the UIScrollView. After the first 18 or so buttons (depending on the screen size) this places any subsequent button out of the visible range of the scroll view, but that’s the whole point. As long as you set the scroll view’s contentSize accordingly, the user can scroll to get to those other buttons.
            scrollView.addSubview(button)
            
            //You use the x and row variables to position the buttons, going from top to bottom (by increasing row). When you’ve reached the bottom (row equals rowsPerPage), you go up again to row 0 and skip to the next column (by increasing the column variable).
            //When the column reaches the end of the screen (equals columnsPerPage), you reset it to 0 and add any leftover space to x (twice the X-margin). This only has an effect on 4-inch and 4.7-inch screens; for the others marginX is 0.
            ++row
            if row == rowsPerPage {
                row = 0
                ++column
                x += itemWidth
                
                if column == columnsPerPage {
                    column = 0
                    x += marginX * 2
                }
            }
            
            
        }//for loop
        
        //At the end of the method you calculate the contentSize for the scroll view based on how many buttons fit on a page and the number of SearchResult objects.
        let buttonsPerPage = columnsPerPage * rowsPerPage
        let numPages = 1 + (searchResults.count - 1) / buttonsPerPage
        
        //You want the user to be able to “page” through these results, rather than simply scroll (a feature that you’ll enable shortly) so you should always make the content width a multiple of the screen width (480, 568, 667 or 736 points).
        scrollView.contentSize = CGSize(
            width: CGFloat(numPages)*scrollViewWidth,
            height: scrollView.bounds.size.height)
        
        //println("Number of pages: \(numPages)")
        
        //This sets the number of dots that the page control displays to the number of pages that you calculated.
        pageControl.numberOfPages = numPages
        pageControl.currentPage = 0
        
        
    }
    
    func buttonPressed(sender: UIButton) {
        performSegueWithIdentifier("ShowDetail", sender: sender)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowDetail" {
            switch search.state {
            case .Results(let list):
                let detailViewController = segue.destinationViewController as DetailViewController
                let searchResult = list[sender!.tag - 2000]
                detailViewController.searchResult = searchResult
            default:
                break
            }
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        //println("deinit \(self)")
        
        for task in downloadTasks {
            task.cancel()
        }
    }

    //You also need to know when the user taps on the Page Control so you can update the scroll view. There is no delegate for this but you can use a regular @IBAction method.
    @IBAction func pageChanged(sender: UIPageControl) {
        
        UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseInOut, animations: {
                self.scrollView.contentOffset = CGPoint(x: self.scrollView.bounds.size.width * CGFloat(sender.currentPage), y:0)
            }, completion: nil)
    }
    
    private func downloadImageForSearchResult(searchResult: SearchResult,
                                                    andPlaceOnButton button: UIButton) {
            //First you get an NSURL object with the URL to the 60×60-pixel artwork, and then create a download task. Inside the completion handler you put the downloaded file into a UIImage, and if all that succeeds, use dispatch_async() to place the image on the button.
            if let url = NSURL(string: searchResult.artworkURL60) {
                let session = NSURLSession.sharedSession()
                let downloadTask = session.downloadTaskWithURL(url,
                        completionHandler: { [weak button] url, response, error in
                            if error == nil && url != nil {
                                if let data = NSData(contentsOfURL: url) {
                                    if let image = UIImage(data: data) {
                                            dispatch_async(dispatch_get_main_queue()) {
                                                if let button = button {
                                                        button.setImage(image, forState: .Normal)
                                                }
                                            }
                                    }
                                }
                            }
                        }
                )
                downloadTask.resume()
                downloadTasks.append(downloadTask)
            }
    }
    
}

extension LandscapeViewController: UIScrollViewDelegate {
    //This is one of the UIScrollViewDelegate methods. You figure out what the index of the current page is by looking at the contentOffset property of the scroll view. This property determines how far the scroll view has been scrolled and is updated while you’re dragging the scroll view.
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let width = scrollView.bounds.size.width
        //Unfortunately, the scroll view doesn’t simply tell us, “The user has flipped to page X”, and so you have to calculate this yourself. If the content offset gets beyond halfway on the page (width/2), the scroll view will flick to the next page. In that case, you update the pageControl’s active page number.
        let currentPage = Int((scrollView.contentOffset.x + width/2) / width)
        pageControl.currentPage = currentPage
    }
}
