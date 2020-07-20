//
//  CoreDataTableVC.swift
//  Fast Playist Maker
//
//

import UIKit
import CoreData

class CoreDataTableVC: UITableViewController, NSFetchedResultsControllerDelegate {

    @objc var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            
            fetchedResultsController?.delegate = self
            search()
            tableView.reloadData()
        }
    }
    
    @objc init(fetchedResultsController fc: NSFetchedResultsController<NSFetchRequestResult>, style: UITableView.Style = .plain) {
        fetchedResultsController = fc
        super.init(style: style)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if let fc = fetchedResultsController {
            return (fc.sections?.count)!
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let fc = fetchedResultsController {
            return fc.sections![section].numberOfObjects
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        fatalError("This method MUST be implemented by a subclass of CoreDataTableViewController")
    }

    @objc func search() {
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
            } catch let err as NSError {
                print("could not perform fetch \(err.localizedDescription)")
            }
        }
    }
//Mark: Fetched results controller delegate
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch(type) {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .fade)
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        @unknown default:
            tableView.reloadData()
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

    

}
