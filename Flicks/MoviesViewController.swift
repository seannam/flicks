//
//  MoviesViewController.swift
//  Flicks
//
//  Created by Sean Nam on 2/4/17.
//  Copyright © 2017 Sean Nam. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
    let refreshControl = UIRefreshControl()
    let baseUrl = "https://image.tmdb.org/t/p/w500/"
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var networkError: UILabel!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var switchToCollectionViewButton: UIBarButtonItem!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    @IBOutlet weak var switchToTableViewButton: UIBarButtonItem!
    
    var movies: [NSDictionary]? = []
    
    var endpoint: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //collectionView.isHidden = true
        self.networkError.isHidden = true
        switchToTableViewButton.isEnabled = false
        //switchToCollectionViewButton.isEnabled = false

        self.refreshControl.addTarget(self, action: #selector(loadMovies), for: UIControlEvents.valueChanged)
        
        tableView.insertSubview(self.refreshControl, at: 0)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        /*
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        */
        
        self.loadMovies()
        
        self.navigationItem.title = "Movies"
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        
        if let navigationBar = navigationController?.navigationBar {
            
            let shadow = NSShadow()
            shadow.shadowColor = UIColor.black.withAlphaComponent(0.5)
            //shadow.shadowOffset = CGSizeMake(2, 2);
            shadow.shadowBlurRadius = 4;
            navigationBar.titleTextAttributes = [
                NSFontAttributeName : UIFont.boldSystemFont(ofSize: 22),
                NSForegroundColorAttributeName : UIColor(red: 0.1, green: 0.1, blue: 0.8, alpha: 0.8),
                NSShadowAttributeName : shadow
            ]
        }
        
    }
    
    func loadMovies() {
        
        let url = URL(string: "https://api.themoviedb.org/3/movie/\(endpoint!)?api_key=\(apiKey)")!
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)

        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        
        // Display HUD right before the request is made
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        let task: URLSessionDataTask = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            
            if error != nil {
                self.networkError.isHidden = false
            }
            // Hide HUD once the network request comes back 
            MBProgressHUD.hide(for: self.view, animated: true)
            
            if let data = data {
                if let dataDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                    
                    self.movies = dataDictionary["results"] as? [NSDictionary]
                    self.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                }
            }
            
        }
        
        task.resume()
    }
    
    @IBAction func tapForCollectionView(_ sender: Any) {
        //collectionView.isHidden = false
        tableView.isHidden = true
        switchToTableViewButton.isEnabled = true
        switchToCollectionViewButton.isEnabled = false
        
    }
    @IBAction func tapForTableView(_ sender: Any) {
        //collectionView.isHidden = true
        tableView.isHidden = false
        switchToTableViewButton.isEnabled = false
        switchToCollectionViewButton.isEnabled = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let movies = movies {
            return movies.count;
        } else {
            return 0
        }
        
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieCell
        
        let movie = movies![indexPath.row]
        let title = movie["title"] as! String
        let overview = movie["overview"] as! String
        
        cell.titleLabel.text = title
        cell.overviewLabel.text = overview
        
        fadeImageIn(cell, movie)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func fadeImageIn(_ cell: MovieCell, _ movie: NSDictionary) {
        //let baseUrl = "https://image.tmdb.org/t/p/w500/"
        
        if let posterPath = movie["poster_path"] as? String {
            //let imageUrl = NSURL(string: baseUrl + posterPath)
            let imageUrl = baseUrl + posterPath
            //cell.posterView.setImageWith(imageUrl! as URL)
            
            let imageRequest = NSURLRequest(url: NSURL(string: imageUrl)! as URL)
            
            cell.posterView.setImageWith(
                imageRequest as URLRequest,
                placeholderImage: nil,
                success: { (imageRequest, imageResponse, image) -> Void in
                    
                    // imageResponse will be nil if the image is cached
                    if imageResponse != nil {
                        print("Image was NOT cached, fade in image")
                        cell.posterView.alpha = 0.0
                        cell.posterView.image = image
                        UIView.animate(withDuration: 0.3, animations: { () -> Void in
                            cell.posterView.alpha = 1.0
                        })
                    } else {
                        print("Image was cached so just update the image")
                        cell.posterView.image = image
                    }
            },
                failure: { (imageRequest, imageResponse, error) -> Void in
                    // do something for the failure condition
                    print("error loading image")
            })
            
        }

    }

    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        let cell = sender as! UITableViewCell
        let indexPath = tableView.indexPath(for: cell)
        let movie = self.movies![(indexPath?.row)!]
        let posterPath = movie["poster_path"] as? String
        
        let popularity = movie["popularity"] as! Double
        print(popularity)
        let rating = movie["vote_average"] as! Double
        print(rating)
        
        let movieId = movie["id"] as? Int
        
        let detailViewController = segue.destination as! DetailViewController
        detailViewController.movie = movie
        detailViewController.posterPath = posterPath
        /*
        detailViewController.movieId = movieId
        
        detailViewController.popularity = popularity
        detailViewController.rating = rating
        */
        
        //print("prepare for segue called from movieviewcontroller")
    }
    
    
}

extension MoviesViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let movies = movies {
            return movies.count;
        } else {
            return 0
        }
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let movies = movies {
            return movies.count;
        } else {
            return 0
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MovieCollectionCell", for: indexPath as IndexPath) as! MovieCollectionCell
        
        let movie = movies![indexPath.row]
        let title = movie["title"] as! String
        
        cell.titleLabel.text = title
        
        if let posterPath = movie["poster_path"] as? String {
            let imageUrl = NSURL(string: baseUrl + posterPath)
            //let imageUrl = baseUrl + posterPath
            cell.posterView.setImageWith(imageUrl! as URL)
        }
        
        //fadePosterImagesIn(cell, movie)
        
        return cell
    }
    func fadePosterImagesIn(_ cell: MovieCollectionCell, _ movie: NSDictionary) {
        //let baseUrl = "https://image.tmdb.org/t/p/w500/"
        
        if let posterPath = movie["poster_path"] as? String {
            //let imageUrl = NSURL(string: baseUrl + posterPath)
            let imageUrl = baseUrl + posterPath
            //cell.posterView.setImageWith(imageUrl! as URL)
            
            let imageRequest = NSURLRequest(url: NSURL(string: imageUrl)! as URL)
            
            cell.posterView.setImageWith(
                imageRequest as URLRequest,
                placeholderImage: nil,
                success: { (imageRequest, imageResponse, image) -> Void in
                    
                    // imageResponse will be nil if the image is cached
                    if imageResponse != nil {
                        print("Image was NOT cached, fade in image")
                        cell.posterView.alpha = 0.0
                        cell.posterView.image = image
                        UIView.animate(withDuration: 0.3, animations: { () -> Void in
                            cell.posterView.alpha = 1.0
                        })
                    } else {
                        print("Image was cached so just update the image")
                        cell.posterView.image = image
                    }
            },
                failure: { (imageRequest, imageResponse, error) -> Void in
                    // do something for the failure condition
                    print("error loading image")
            })
            
        }
        
    }
}
