//
//  MenuTableViewController.swift
//  Order App
//
//  Created by Anush Yerzinkyan on 30.10.22.
//

import UIKit

class MenuTableViewController: UITableViewController {
    let category: String
    var menuItems = [MenuItem]()
    var imageLoadTasks: [IndexPath: Task<Void, Never>] = [:]

    init?(coder: NSCoder, category: String) {
        self.category = category
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = category.capitalized

        Task.init {
            do {
                let menuItems = try await
                MenuController.shared.fetchMenuItems(forCategory: category)
                updateUI(with: menuItems)
            } catch {
                displayError(error, title: "Failed to Fetch Menu Items for \(self.category)")
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        MenuController.shared.updateUserActivity(with: .menu(category: category))
    }

    func updateUI(with menuItems: [MenuItem]) {
        self.menuItems = menuItems
        self.tableView.reloadData()
    }

    func displayError(_ error: Error, title: String) {
        // swiftlint:disable:next unused_optional_binding
        guard let _ = viewIfLoaded?.window else { return }
        let alert = UIAlertController(title: title, message:
            error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss",
                                      style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier:
        "MenuItem", for: indexPath)
        configure(cell, forItemAt: indexPath)
        return cell
    }

    func configure(_ cell: UITableViewCell, forItemAt indexPath: IndexPath) {
         guard let cell = cell as? MenuItemCell else { return }

        let menuItem = menuItems[indexPath.row]

            cell.itemName = menuItem.name
            cell.price = menuItem.price
            cell.image = nil

        imageLoadTasks[indexPath] = Task.init {
            if let image = try? await
                MenuController.shared.fetchImage(from: menuItem.imageURL) {
                if let currentIndexPath = self.tableView.indexPath(for: cell),
                   currentIndexPath == indexPath {
                    cell.image = image
                }
            }
            imageLoadTasks[indexPath] = nil
        }
    }

    @IBSegueAction func showMenuItem(_ coder: NSCoder, sender: Any?) -> MenuItemDetailViewController? {
        guard
            let cell = sender as? UITableViewCell,
            let indexPath = tableView.indexPath(for: cell)
        else { return nil }

        let menuItem = menuItems[indexPath.row]
        return MenuItemDetailViewController(coder: coder, menuItem: menuItem)
    }

    override func tableView(
        _ tableView: UITableView,
        didEndDisplaying cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        // Cancel the image fetching task if it's no longer needed
        imageLoadTasks[indexPath]?.cancel()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // swiftlint:disable:next unused_closure_parameter
        imageLoadTasks.forEach { key, value in value.cancel() }
    }
}
