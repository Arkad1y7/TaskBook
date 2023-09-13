
import UIKit
import RealmSwift
import ChameleonFramework

class ViewController: SwipeTableViewController {
    
    var taskItems: Results<Item>?
    let realm = try! Realm()
    
    @IBOutlet weak var searchBar: UISearchBar!
    var selectedCategory: Category? {
        didSet{
            loadItems()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 80.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let colorHex = selectedCategory?.color{
            title = selectedCategory!.name
            guard let navBar = navigationController?.navigationBar else {fatalError("NavigationController does not exist.")}
            if let navBarColor = UIColor(hexString: colorHex){
                navBar.backgroundColor = navBarColor
                navBar.tintColor = ContrastColorOf(navBarColor, returnFlat: true)
                navBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : ContrastColorOf(navBarColor, returnFlat: true)]
                searchBar.barTintColor = navBarColor
            }
        }
    }
    //MARK: - Add New Items
    
    @IBAction func AddItems(_ sender: UIBarButtonItem) {
        var field = UITextField()
        let alert = UIAlertController(title: "Create New Item", message: " ", preferredStyle: .alert)
        let action = UIAlertAction(title: "Add", style: .default){(action) in
            if let currentCategory = self.selectedCategory{ 
                do{
                    try self.realm.write{
                        let newItem = Item()
                        newItem.title = field.text!
                        newItem.dateCreated = Date()
                        newItem.color = UIColor.randomFlat().hexValue()
                        currentCategory.items.append(newItem)
                    }
                }catch{
                    print("Error saving new items \(error)")
                }
            }
            self.tableView.reloadData()
        }
        
        alert.addTextField{(AlertField) in AlertField.placeholder = "Enter item"
            field = AlertField
        }
        alert.addAction(action)
        present(alert, animated: true)
    }
    //MARK: - TableView Datasource Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskItems?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        let modifiedCell = SettingUpACell(cell: cell, indexPath: indexPath)
        
        return modifiedCell
    }
    
    func SettingUpACell(cell: UITableViewCell, indexPath: IndexPath) -> UITableViewCell{
        if let item = taskItems?[indexPath.row]{
            guard let categoryColor = UIColor(hexString: selectedCategory!.color) else {fatalError("viewController guard error")}
            let color = categoryColor.darken(byPercentage: CGFloat(indexPath.row) / CGFloat(taskItems!.count))
            cell.textLabel?.text = item.title
            cell.backgroundColor = color
            cell.textLabel?.textColor = ContrastColorOf(color!, returnFlat: true)
            cell.accessoryType = item.done ? .checkmark : .none
        }
        return cell

    }
    
    //MARK: - TableView Delegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let item = taskItems?[indexPath.row] {
            
            do{
                try realm.write{
                    item.done = !item.done
                }
            }catch {
                print("Error saving done status, \(error)")
            }
        }
        tableView.reloadData()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: - Model Manipulations Methods
    func loadItems(){
        taskItems = selectedCategory?.items.sorted(byKeyPath: "title", ascending: true)
        tableView.reloadData()
    }
    
    //MARK: - Delete Data From Swipe
    override func updateModel(at indexPath: IndexPath) {
        if let deletingItem = taskItems?[indexPath.row]{
            do{
                try self.realm.write{
                    self.realm.delete(deletingItem)
                }
            }catch{
                print("Error deleting item \(error)")
            }
        }
    }
}




//MARK: - Search bar methods
extension ViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        taskItems = taskItems?.filter("title CONTAINS[cd] %@", searchBar.text!).sorted(byKeyPath: "dateCreated", ascending: true)
        tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            loadItems()

            DispatchQueue.main.async {
                searchBar.resignFirstResponder() // для того чтобы убрать клавиатуру // переключить основное окно
            }
        } // Вызовы DispatchQueue.main.async нужны нам для того, чтобы вернуть выполнение кода в основной поток, поскольку обратный вызов задачи данных выполняется в фоновом потоке.
    }
}
