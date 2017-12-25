pragma solidity ^0.4.19;


contract Market {
    
    struct Product {
        uint256 _price;
        string _name;
        uint256 _quantity;
        address _farmer; 
        string _additionalInfo;
        mapping(address => uint) rate;
        address[] _rater;
    } 
    
    mapping(uint => Product) public products;
    uint[] public _products;
    
    function totalProducts() public constant returns(uint) {
        return _products.length;
    }
    
    function getProduct(uint _product_id) public constant returns(uint256, string, uint256, address, string/*, uint*/) {
        return (products[_product_id]._price, 
        products[_product_id]._name, 
        products[_product_id]._quantity, 
        products[_product_id]._farmer, 
        products[_product_id]._additionalInfo/*,
        products[_product_id].rate[products[_product_id]._rater[0]]*/);
    }
   
    address public owner;   // владелец  маркета
    
    function Market() public {
        owner = msg.sender;
    }
    
    function addProduct (
        uint256 _price,
        string _name,
        uint256 _quantity,
        uint256 _product_id,
        address _farmer,
        string _additionalInfo
    ) public {
        Product memory p;
        p._price = _price;
        p._name = _name;
        p._quantity = _quantity;
        p._farmer = _farmer;
        p._additionalInfo = _additionalInfo;
        //p._rater[0] = _farmer;
        products[_product_id] = p;
        _products.push(_product_id);
    }

   
    struct Purchase {
        uint deal_id;
        uint product_id;
        uint256 quantity;
        address buyer;
        bool delivered;
    }

    /* mapping для Purchase, чтобы можно было искать по индексу*/
    mapping(uint => Purchase) public _purchases;
    uint[] public purchases;
    
    
    function totalPurchases() public constant returns(uint) {
        return purchases.length;
    }
    
    event Purchased(address farmer, uint product_id);
    
    function deal (uint _product_id, uint256 _quantity) payable public {                   // покупатель
        uint _deal_id;
        if (purchases.length == 0) {_deal_id = 1;}
        else {_deal_id = purchases[purchases.length-1]+1;}
        _purchases[_deal_id] = Purchase(_deal_id, _product_id, _quantity, msg.sender, false);
		
        /* ОПЛАТА */ 
        require(_quantity <= products[_product_id]._quantity);
        require(msg.value >= products[_product_id]._price*_quantity);
        
        /*Деньги, полученные контрактом от покупателя, передаются на кошелек фермера*/
        products[_product_id]._farmer.transfer(this.balance);
        
        /* уменьшаем количество */
        products[_product_id]._quantity -= _quantity;
        
        // event фермеру что совершена покупка
        Purchased(products[_product_id]._farmer, _product_id);
        
        /* здесь пушим сделку в массив*/
        purchases.push(_deal_id);
    }
    
    function getRate(uint _product_id) public constant returns(uint) {
		uint len = products[_product_id]._rater.length;
        uint total = 0;
        for (uint i = 0; i < len; i++) {
            address rater = products[_product_id]._rater[i];
            total += products[_product_id].rate[rater];
        }
        if (total == 0) {
            return 0;
        }
        else {
            return (total / len);
        }
    }
    
    function rate(uint _id, uint _rate) public {
        uint pid = _purchases[_id].product_id;
        products[pid].rate[msg.sender] = _rate;
        products[pid]._rater.push(msg.sender);
        _purchases[_id].delivered = true;
    }
    
}
