// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "../Ownable.sol";

contract CinemaaTicketBook is Ownable {
    struct Booking {
        uint bookId;
        uint amount;
        uint totalTicket;
        bool isPaid;
        uint[] seats;
        uint studiosId;
        uint totalBalance;
    }

    struct CinemaStudio {
        uint studioId;
        string movieTitle;
        uint priceMovie;
        bool seat1;
        bool seat2;
        bool seat3;
    }

    struct Order {
        uint orderId;
        uint noTicket;
    }

    mapping(uint => CinemaStudio) public Theater;

    mapping(address => Booking) Book;

    mapping(uint => Order) Orders;

    uint indexOrder = 1;
    uint indexBook = 1;

    constructor() {
        Theater[0].studioId = 1;
        Theater[0].movieTitle = "Doctor Strange";
        Theater[0].priceMovie = 1 ether;
        Theater[0].seat1 = false;
        Theater[0].seat2 = false;
        Theater[0].seat3 = false;

        Theater[1].studioId = 2;
        Theater[1].movieTitle = "The Amazing Spider-Man";
        Theater[1].priceMovie = 1 ether;
        Theater[1].seat1 = false;
        Theater[1].seat2 = false;
        Theater[1].seat3 = false;

        Theater[2].studioId = 3;
        Theater[2].movieTitle = "Shang-Chi and The Legend of The Ten Rings";
        Theater[2].priceMovie = 1 ether;
        Theater[2].seat1 = false;
        Theater[2].seat2 = false;
        Theater[2].seat3 = false;
    }

    function bookingSeat(uint _theater, uint _seat) public 
        checkSeatOne(_theater, _seat) checkSeatTwo(_theater, _seat) checkSeatThree(_theater, _seat) 
        returns(bool success) {
    
        if(_seat == 1) {
            Theater[_theater].seat1 = true;
            Book[msg.sender].seats.push(1);
            Book[msg.sender].totalTicket += 1;
        } else if (_seat == 2) {
            Theater[_theater].seat2 = true;
            Book[msg.sender].seats.push(2);
            Book[msg.sender].totalTicket += 1;
        } else {
            Theater[_theater].seat3 = true;
            Book[msg.sender].seats.push(3);
            Book[msg.sender].totalTicket += 1;
        }
        
        Book[msg.sender].bookId = indexBook;
        Book[msg.sender].amount = Book[msg.sender].totalTicket * Theater[_theater].priceMovie;
        Book[msg.sender].studiosId = Theater[_theater].studioId;
        Book[msg.sender].isPaid = false;
        return true;
    }

    function paymentBooking() payable external checkBalance() checkBook() 
        returns(bool success) {

        Book[msg.sender].isPaid = true;

        Orders[Book[msg.sender].bookId].orderId = indexOrder;
        Orders[Book[msg.sender].bookId].noTicket = block.timestamp;
        
        indexOrder++;
        indexBook++;

        uint balanceToSend = 0;
        uint refund = 0;
        
        if (msg.value > Book[msg.sender].amount) {
            refund = msg.value - Book[msg.sender].amount;
            payable(msg.sender).transfer(refund);
        }

        balanceToSend = msg.value - refund;
        owner.transfer(balanceToSend);
        return true;
    }
    
    function getTheater() public view returns (uint[] memory studioId, string[] memory moviesTitle,
        uint[] memory pricesMovie) {
      uint[] memory id = new uint[](3);
      string[] memory title = new string[](3);
      uint[] memory prices = new uint[](3);
      for (uint i = 0; i < 3; i++) {
          CinemaStudio storage cinemas = Theater[i];
          id[i] = cinemas.studioId;
          title[i] = cinemas.movieTitle;
          prices[i] = cinemas.priceMovie;
      }
      return (id, title, prices);
    }
    
    function getBooking() public view returns (uint _id, uint _amount, uint[] memory _seat,
        uint _totalTicket, bool _isPaid) {
        uint lengths = Book[msg.sender].seats.length;
        
        uint id = Book[msg.sender].bookId;
        uint amount = Book[msg.sender].amount;
        uint totalTicket = Book[msg.sender].totalTicket;
        bool isPaid = Book[msg.sender].isPaid;

        uint[] memory seat = new uint[](lengths);

        Booking storage books = Book[msg.sender];
        for (uint i = 0; i < lengths; i++) {
            seat[i] = books.seats[i];
        }

        return (id, amount, seat, totalTicket, isPaid);
    }

    function printTicket(uint _bookId) public view returns(uint _id, uint _noTicket,
        uint[] memory _seat, bool _isPaid) {
        uint lengths = Book[msg.sender].seats.length;
        uint id = Orders[_bookId].orderId;
        uint noTicket = Orders[_bookId].noTicket;
        bool isPaid = Book[msg.sender].isPaid;
        uint[] memory seat = new uint[](lengths);

        Booking storage books = Book[msg.sender];
        for (uint i = 0; i < lengths; i++) {
            seat[i] = books.seats[i];
        }

        return (id, noTicket, seat, isPaid);
    }

    modifier isOwner {
        require(owner == msg.sender, "fungsi ini hanya boleh diakses owner");
        _;
    }

    modifier checkBook() {
        uint ids = Book[msg.sender].bookId;
        require(ids != 0, "You haven't booked");
        _;
    }

    modifier checkBalance() {
        uint _cost = Book[msg.sender].amount;
        require(msg.value >= _cost, "not enough funds");
        _;
    }

    modifier checkSeatOne(uint _theater, uint _seat1) {
        bool seats1 = _seat1 == 1 && Theater[_theater].seat1;
        require(seats1 == false, "seat 1 not available");
        _;
    }
    modifier checkSeatTwo(uint _theater, uint _seat2) {
        bool seats2 = _seat2 == 2 && Theater[_theater].seat2;
        require(seats2 == false, "seat 2 not available");
        _;
    }

    modifier checkSeatThree(uint _theater, uint _seat3) {
        bool seats3 = _seat3 == 3 && Theater[_theater].seat3;
        require(seats3 == false, "seat 3 not available");
        _;
    }
}