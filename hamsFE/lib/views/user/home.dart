import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<StatefulWidget> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  // String _userInput = '';

  // late Future<List<Book>> newBooksFuture;
  // late Future<List<Book>> topRatedBooksFuture;
  // late Future<List<Book>> mostBorrowedBooksFuture;

  @override
  void initState() {
    super.initState();
    // newBooksFuture = ApiService.getBooksFiltered(BookFilter.newRelease);
    // topRatedBooksFuture = ApiService.getBooksFiltered(BookFilter.topRated);
    // mostBorrowedBooksFuture = ApiService.getBooksFiltered(BookFilter.mostBorrowed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(left: 25, right: 25, top: 40),
        physics: BouncingScrollPhysics(),
        children: [
          // Greeting user
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, ${thisUser!.name}',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey),
              ),
              Text(
                'Explore the world of books',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black),
              ),
            ],
          ),
        ],
      ),
    );
  }
}