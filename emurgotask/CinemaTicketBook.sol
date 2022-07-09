// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;


contract CinemaaTicketBook {
    address payable public owner;

    uint public countMovie = 0;
    uint public countBooking = 1;
    uint totalFund = 0;

    enum MovieTypes {ACTION, COMEDY, DRAMA}

    struct Booking {
        uint bookId;
        uint amount;
        uint[] seats;
        uint movieId;
        bool isPaid;
        address payable currentCustomer;    
    }

    struct Movie {
        uint movieId;
        string movieTitle;
        uint moviePrice;
        MovieTypes movieTypes;
        uint[] seatId;
    }

    mapping(uint => Movie) Movies;

    mapping(uint => Booking) Bookings;

    uint indexOrder = 1;

    constructor() {
        owner = msg.sender;
    }

    modifier isOwner {
        require (owner == msg.sender, "You are not owner");
        _;
    }

    modifier isNotOwner {
        require (owner != msg.sender, "You are not customer");
        _;
    }

    modifier isMovieAvailable(uint _movieId) {
        require(Movies[_movieId].movieId != 0, "The Movie is not Available");
        _;
    }

    modifier ChooseSeats(uint _seatId) {
        require(_seatId <= 5, "Select Seat Between seat 1 to seat 5.");
        _;
    }

    modifier checkBook(uint _bookId) {
        uint ids = Bookings[_bookId].bookId;
        require(ids != 0, "You haven't booked");
        _;
    }

    modifier checkBalance(uint _bookId) {
        uint _cost = Bookings[_bookId].amount;
        require(msg.value >= _cost, "not enough funds");
        _;
    }

    modifier checkPaid(uint _bookingId) {
        require(!Bookings[_bookingId].isPaid, "You already paid");
        _;
    }

    modifier isSeatAvailableMovie(uint _movieId, uint _seatId) {

        bool availableSeat = false;
        for (uint i = 0; i < Movies[_movieId].seatId.length; i++) {
            if (_seatId == Movies[_movieId].seatId[i]) {
                availableSeat = true;
            }
        }
        require(!availableSeat, "Seat are filled");
        _;
    }

    modifier isSeatAvailable(uint _seatId) {
        if (Bookings[countBooking].currentCustomer != msg.sender) {
            delete Bookings[countBooking].seats;
        }

        bool availableSeat = false;
        for (uint i = 0; i < Bookings[countBooking].seats.length; i++) {
            if (_seatId == Bookings[countBooking].seats[i]) {
                availableSeat = true;
            }
        }
        require(!availableSeat, "Seat are booked");
        _;
    }

    function addMovie(string memory _movieTitle, uint _moviePrice, MovieTypes _movieTypes) external isOwner {
        countMovie++;
        // create movie
        Movies[countMovie].movieId = countMovie;
        Movies[countMovie].movieTitle = _movieTitle;
        Movies[countMovie].moviePrice = _moviePrice;
        Movies[countMovie].movieTypes = _movieTypes;
    }

    function bookingMovies(uint _movieId, uint _seatId) external payable isNotOwner isMovieAvailable(_movieId) ChooseSeats(_seatId) isSeatAvailable(_seatId) isSeatAvailableMovie(_movieId, _seatId)   {
        
        // create booking
        Bookings[countBooking].bookId = countBooking;
        Bookings[countBooking].movieId = _movieId;
        Bookings[countBooking].seats.push(_seatId);
        Bookings[countBooking].currentCustomer = msg.sender;

        // update amount
        Bookings[countBooking].amount = Bookings[countBooking].seats.length * Movies[_movieId].moviePrice;
    }

    function paymentMovies(uint _bookingId) payable external checkBalance(_bookingId) checkBook(_bookingId) checkPaid(_bookingId) {
        Booking memory bookings = Bookings[_bookingId];
        
        uint totalFee = Bookings[_bookingId].amount;
        uint refundFee = 0;

        Bookings[_bookingId].isPaid = true;
        countBooking++;

        // update seat movie
        for (uint i = 0; i < Bookings[_bookingId].seats.length; i++) {
            Movies[Bookings[_bookingId].movieId].seatId.push(Bookings[_bookingId].seats[i]);
        }

        if (msg.value > Bookings[_bookingId].amount) {
            refundFee = msg.value - Bookings[_bookingId].amount;
        }

        address payable customer = bookings.currentCustomer;
        // refund fee to sender
        customer.transfer(refundFee);

        owner.transfer(totalFee);
    }

    function finishMovie(uint _movieId) external isOwner isMovieAvailable(_movieId) returns(bool success) {
        delete Movies[_movieId].seatId;

        return true;
    }

   function getBooking(uint _bookId) public view returns (uint _id, uint _amount, uint[] memory _seat,
        uint _movieId, bool _isPaid) {
        uint lengths = Bookings[_bookId].seats.length;
        
        uint id = Bookings[_bookId].bookId;
        uint amount = Bookings[_bookId].amount;
        bool isPaid = Bookings[_bookId].isPaid;
        uint movieId = Bookings[_bookId].movieId;

        uint[] memory seat = new uint[](lengths);

        Booking storage books = Bookings[_bookId];
        for (uint i = 0; i < lengths; i++) {
            seat[i] = books.seats[i];
        }

        return (id, amount, seat, movieId, isPaid);
    }

    function getMovies(uint _movieId) public view returns (uint _id, string memory _movieTitle, uint _moviePrice, 
        uint[] memory _seat, MovieTypes _movieTypes) {
        uint lengths = Movies[_movieId].seatId.length;
        
        uint id = Movies[_movieId].movieId;
        string memory movieTitle = Movies[_movieId].movieTitle;
        uint moviePrice = Movies[_movieId].moviePrice;
        MovieTypes movieTypes = Movies[_movieId].movieTypes;

        uint[] memory seat = new uint[](lengths);

        Movie storage moviess = Movies[_movieId];
        for (uint i = 0; i < lengths; i++) {
            seat[i] = moviess.seatId[i];
        }

        return (id, movieTitle, moviePrice, seat, movieTypes);
    }
}
