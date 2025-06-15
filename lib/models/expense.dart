import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

const uuid = Uuid();

final formatter = DateFormat.yMd();

enum Category { food, travel, entertainment, work }

const categoryIcons = {
  Category.food: Icons.lunch_dining,
  Category.travel: Icons.motorcycle,
  Category.entertainment: Icons.tv,
  Category.work: Icons.work,
};

class Expense {
  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
     // Added description field
  });

  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final Category category;
   // Store description in the class

  // The formatted date for displaying in the UI
  String get formattedDate {
    return formatter.format(date);
  }

  // Getter for description
   // Getter method for description

  // Method to copy the Expense object with modified fields
  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    Category? category,
     // Added description to the copyWith method
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
       // Handle description copy
    );
  }

  // Convert Expense to Firestore Map for storing in Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category.name, // Store enum as a string
       // Store description field
    };
  }

  // Convert Firestore Map to Expense
  static Expense fromFirestore(Map<String, dynamic> data) {
    return Expense(
      id: data['id'] as String,
      title: data['title'] as String,
      amount: data['amount'] as double,
      date: DateTime.parse(data['date'] as String),
      category: Category.values.firstWhere((e) => e.name == data['category']),
       // Extract description
    );
  }
}

class BucketExpense {
  final Category category;
  final List<Expense> expenses;

  BucketExpense({required this.category, required this.expenses});

  // Filter expenses by category
  BucketExpense.forCategory(List<Expense> allExpenses, this.category)
      : expenses = allExpenses
            .where((expense) => expense.category == category)
            .toList();

  // Get the total of all expenses in the bucket
  double get totalExpenses {
    double sum = 0;
    for (final expense in expenses) {
      sum += expense.amount;
    }
    return sum;
  }
}
