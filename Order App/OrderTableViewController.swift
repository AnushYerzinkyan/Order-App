//
//  OrderTableViewController.swift
//  Order App
//
//  Created by Anush Yerzinkyan on 30.10.22.
//

import UIKit

class OrderTableViewController: UITableViewController {

    var minutesToPrepareOrder = 0
    var imageLoadTasks: [IndexPath: Task<Void, Never>] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

    navigationItem.leftBarButtonItem = editButtonItem

    NotificationCenter.default.addObserver(tableView!,
    selector: #selector(UITableView.reloadData),
    name: MenuController.orderUpdatedNotification, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        MenuController.shared.updateUserActivity(with: .order)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MenuController.shared.order.menuItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Order", for: indexPath)
        configure(cell, forItemAt: indexPath)
        return cell
    }

    func configure(_ cell: UITableViewCell, forItemAt indexPath: IndexPath) {
        let menuItem = MenuController.shared.order.menuItems[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = menuItem.name
        content.secondaryText = menuItem.price.formatted(.currency(code: "usd"))
        content.image = UIImage(systemName: "photo.on.rectangle")
        content.imageProperties.reservedLayoutSize = CGSize(width: 50, height: 50)
        imageLoadTasks[indexPath] = Task.init {
            if let image = try? await
                MenuController.shared.fetchImage(from: menuItem.imageURL) {
                if let currentIndexPath = self.tableView.indexPath(for: cell),
                   currentIndexPath == indexPath {

                    content.image = image
                    content.imageProperties.maximumSize = CGSize(width: 40, height: 40)
                    cell.contentConfiguration = content
                }
            }
            imageLoadTasks[indexPath] = nil
        }
        cell.contentConfiguration = content
    }

    override func tableView(_ tableView: UITableView,
        // swiftlint:disable:next vertical_parameter_alignment
        canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView,
        // swiftlint:disable:next vertical_parameter_alignment
        commit editingStyle: UITableViewCell.EditingStyle,
        // swiftlint:disable:next vertical_parameter_alignment
        forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            MenuController.shared.order.menuItems.remove(at: indexPath.row)
        }
    }

    @IBSegueAction func confirmOrder(_ coder: NSCoder) ->
       OrderConfirmationViewController? {
        return OrderConfirmationViewController(coder: coder,
           minutesToPrepare: minutesToPrepareOrder)
    }

    @IBAction func unwindToOrderList(segue: UIStoryboardSegue) {
        if segue.identifier == "DismissConfirmation" {
            MenuController.shared.order.menuItems.removeAll()
        }
    }

    func uploadOrder() {
        let menuIds = MenuController.shared.order.menuItems.map { $0.id }
        Task.init {
            do {
                let minutesToPrepare = try await
                   MenuController.shared.submitOrder(forMenuIDs: menuIds)
                minutesToPrepareOrder = minutesToPrepare
                performSegue(withIdentifier: "confirmOrder", sender: nil)
            } catch {
                displayError(error, title: "Order Submission Failed")
            }
        }
    }

    func displayError(_ error: Error, title: String) {
        // swiftlint:disable:next unused_optional_binding
        guard let _ = viewIfLoaded?.window else { return }
        let alert = UIAlertController(title: title, message:
           error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default,
           handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    @IBAction func submitTapped(_ sender: Any) {
        let orderTotal = MenuController.shared.order.menuItems.reduce(0.0) { (result, menuItem) -> Double in
            return result + menuItem.price
        }

        let formattedTotal = orderTotal.formatted(.currency(code: "usd"))

        let alertController = UIAlertController(
            title: "Confirm Order",
            message: "You are about to submit your order with a total of \(formattedTotal)",
           preferredStyle: .actionSheet
        )
        alertController.addAction(UIAlertAction(title: "Submit",
           style: .default, handler: { _ in
            self.uploadOrder()
        }))

        alertController.addAction(UIAlertAction(title: "Cancel",
           style: .cancel, handler: nil))

        present(alertController, animated: true, completion: nil)
    }
}
