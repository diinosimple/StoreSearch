//
//  SearchResultCell.swift
//  StoreSearchSwift
//
//  Created by Iino Daisuke on 2014/11/29.
//  Copyright (c) 2014年 Iino Daisuke. All rights reserved.
//

import UIKit

class SearchResultCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var artworkImageView: UIImageView!
    
    var downloadTask: NSURLSessionDownloadTask?
    
    //The awakeFromNib() method is called after this cell object has been loaded from the nib but before the cell is added to the table view. You can use this method to do additional work to prepare the object for use. That’s perfect for creating the view with the selection color.
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let selectedView = UIView(frame: CGRect.zeroRect)
        selectedView.backgroundColor = UIColor(red: 20/255, green: 160/255, blue: 160/255, alpha: 0.5)
        selectedBackgroundView = selectedView
        
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    //How was that for easy? You’re not quite done yet. Remember that table view cells can be reused, so it’s theoretically possible that you’re scrolling through the table and some cell is about to be reused while its previous image is still loading.
    //You no longer need that image so you should really cancel the pending download. Table view cells have a special method named prepareForReuse() that is ideal for this.
    
    override func prepareForReuse() {
        super.prepareForReuse()
        //Here you cancel any image download that is still in progress. For good measure you also clear out the text from the labels. It’s always a good idea to play nice.
        downloadTask?.cancel()
        downloadTask = nil
        nameLabel.text = nil
        artistNameLabel.text = nil
        artworkImageView.image = nil
        
    }
    
    func configureForSearchResult (searchResult: SearchResult) {
        nameLabel.text = searchResult.name
        
        if searchResult.artistName.isEmpty {
            artistNameLabel.text = "Unknown"
        } else {
            artistNameLabel.text = String(format: "%@ (%@)", searchResult.artistName, searchResult.kindForDisplay())
        }
        
        artworkImageView.image = UIImage(named: "Placeholder")
        if let url = NSURL(string: searchResult.artworkURL60) {
            downloadTask = artworkImageView.loadImageWithURL(url)
        }
    }

}
