import 'package:flutter/material.dart';

class MyRentalsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Setting background color to dark grey
      appBar: AppBar(
        title: Text(
          'My Rentals',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 20), // Adding space between app bar and first rental item
            RentalItemWidget(
              imageUrl: 'assets/car.png',
              dateRange: '2023/04/15 - 2023/04/17',
              carName: 'BMW 4 Series',
              price: '541.56',
            ),
            SizedBox(height: 20), // Adding space between first and second rental item
            RentalItemWidget(
              imageUrl: 'assets/car.png',
              dateRange: '2023/04/18 - 2023/04/20',
              carName: 'Audi A6',
              price: '635.79',
            ),
          ],
        ),
      ),
    );
  }
}

class RentalItemWidget extends StatelessWidget {
  final String imageUrl;
  final String dateRange;
  final String carName;
  final String price;

  RentalItemWidget({
    required this.imageUrl,
    required this.dateRange,
    required this.carName,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16), // Increase margin to make container bigger
      padding: EdgeInsets.all(10), // Adding padding for better spacing
      decoration: BoxDecoration(
        color: Colors.grey[900], // Setting background color to black
        borderRadius: BorderRadius.circular(10), // Adding border radius for rounded corners
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            imageUrl,
            width: double.infinity,
            height: 150, // Increase image height for larger image
            fit: BoxFit.cover,
          ),
          SizedBox(height: 10), // Adding space between image and text
          Text(
            dateRange,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 18, // Larger font size for date range
            ),
          ),
          SizedBox(height: 5), // Adding space between date range and car name
          Text(
            carName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16, // Smaller font size for car name
            ),
          ),
          SizedBox(height: 5), // Adding space between car name and price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$$price',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16, // Smaller font size for price
                ),
              ),
              Text(
                'Total',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14, // Smaller font size for "Total"
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(home: MyRentalsWidget()));
}
