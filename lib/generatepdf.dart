import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_auth/firebase_auth.dart'; // To get user name
import 'package:cloud_firestore/cloud_firestore.dart'; // To fetch user expenses

class GeneratePDF extends StatelessWidget {
  final String userId;

  GeneratePDF({required this.userId});

  Future<pw.Document> createPDF() async {
    final pdf = pw.Document();

    // Fetch user data (name) and expenses from Firestore
    final user = await FirebaseAuth.instance.currentUser;
    final userExpenses = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .get();

    List<List<String>> expensesList = [];
    double totalExpense = 0.0;

    // Check if expenses are fetched correctly from Firestore
    for (var doc in userExpenses.docs) {
      var expenseData = doc.data();

      // Ensure expenseData contains the correct fields
      print("Expense Data: ${expenseData.toString()}"); // Debug print

      double amount = expenseData['amount'] ??
          0.0; // Fallback to 0.0 if 'amount' is not found
      String title = expenseData['title'] ??
          'No Title'; // Default value if 'title' is not found
      String category = expenseData['category'] ??
          'Unknown'; // Default value if 'category' is not found
      String dateStr =
          expenseData['date'] ?? ''; // Default value if 'date' is not found

      DateTime? date = dateStr.isNotEmpty ? DateTime.tryParse(dateStr) : null;
      String formattedDate = date != null
          ? '${date.month}/${date.day}/${date.year}'
          : 'Unknown Date';

      totalExpense += amount; // Add the amount to the total

      expensesList.add([
        title,
        '\$${amount.toStringAsFixed(2)}', // Format amount
        formattedDate,
        category,
      ]);
    }

    // Adding user name and expense list to PDF
    pdf.addPage(pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Expense Report for ${user?.displayName ?? "User"}',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('List of Expenses:', style: pw.TextStyle(fontSize: 18)),
            pw.TableHelper.fromTextArray(
              headers: ['Title', 'Amount', 'Date', 'Category'],
              data: expensesList,
            ),
            pw.SizedBox(height: 20),
            pw.Text('Total Expense: \$${totalExpense.toStringAsFixed(2)}'),
          ],
        );
      },
    ));

    return pdf;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Expense Report'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final pdf = await createPDF();
            await Printing.layoutPdf(onLayout: (format) async => pdf.save());
          },
          child: const Text('Generate PDF'),
        ),
      ),
    );
  }
}
