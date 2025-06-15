import 'dart:io'; // For file handling
import 'package:expense_tracker/widgets/chart/chart.dart';
import 'package:expense_tracker/widgets/expense_list/expense_list.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/widgets/new_expense.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart'; // For saving the file

class Expenses extends StatefulWidget {
  const Expenses({super.key});

  @override
  State<Expenses> createState() {
    return _ExpensesState();
  }
}

class _ExpensesState extends State<Expenses> {
  final List<Expense> _listOfExpenses = [];
  double _totalExpenses = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserExpenses(); // Load expenses when the widget is initialized
  }

  // Load expenses for the signed-in user
  Future<void> _loadUserExpenses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('userId', isEqualTo: user.uid)
          .get();

      final expenses = snapshot.docs.map((doc) {
        return Expense.fromFirestore(doc.data());
      }).toList();

      setState(() {
        _listOfExpenses.clear();
        _listOfExpenses.addAll(expenses);

        _totalExpenses =
            _listOfExpenses.fold(0.0, (sum, item) => sum + item.amount);
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to load expenses: $error'),
      ));
    }
  }

  void _addNewExpense(Expense expense) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final expenseRef = await FirebaseFirestore.instance
          .collection('expenses')
          .add(expense.toFirestore()..['userId'] = user.uid);

      setState(() {
        _listOfExpenses.add(expense.copyWith(id: expenseRef.id));
        _totalExpenses += expense.amount;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to add expense: $error'),
      ));
    }
  }

  void _addExpenseOverlay() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      useSafeArea: true,
      builder: (ctx) => NewExpense(
        onAddExpense: _addNewExpense,
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signed out successfully!'),
          duration: const Duration(seconds: 2),
        ),
      );
      // Navigate to login screen or home screen after sign out
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sign out: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _removeExpense(Expense expense) async {
    final expenseIndex = _listOfExpenses.indexOf(expense);
    setState(() {
      _listOfExpenses.remove(expense);
      _totalExpenses -= expense.amount;
    });

    await FirebaseFirestore.instance
        .collection('expenses')
        .doc(expense.id)
        .delete()
        .catchError((error) {
      print("Failed to delete expense from Firestore: $error");
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: Text('Expense Deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _listOfExpenses.insert(expenseIndex, expense);
              _totalExpenses += expense.amount;
            });
          },
        ),
      ),
    );
  }

  Future<void> _generateAndSavePDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text('Expenses Report', style: pw.TextStyle(fontSize: 30)),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  // Header row
                  pw.TableRow(
                    children: [
                      pw.Text('Date',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Amount',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Title',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Category',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  // Expense rows
                  ..._listOfExpenses.map((expense) {
                    return pw.TableRow(
                      children: [
                        pw.Text(DateFormat('yyyy-MM-dd').format(expense.date)),
                        pw.Text('PKR ${expense.amount.toStringAsFixed(2)}'),
                        pw.Text(expense.title),
                        pw.Text(expense.category.toString()),
                      ],
                    );
                  }).toList(),
                  // Total expense row
                  pw.TableRow(
                    children: [
                      pw.Text('Total',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      pw.Text('PKR ${_totalExpenses.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      pw.Text(''),
                      pw.Text(''),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    final outputDirectory = await getApplicationDocumentsDirectory();
    final filePath = '${outputDirectory.path}/expenses_report.pdf';
    final file = File(filePath);

    await file.writeAsBytes(await pdf.save());

    await Printing.sharePdf(
        bytes: await pdf.save(), filename: 'expenses_report.pdf');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF saved and shared: $filePath')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    Widget mainContent = const Center(
      child: Text('No Expense Added. Start Managing Your Expenses'),
    );

    if (_listOfExpenses.isNotEmpty) {
      mainContent = ExpenseList(
        expenses: _listOfExpenses,
        removeExpense: _removeExpense,
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true, // Centers the title
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Budget Buddy',
              style: GoogleFonts.oswald(
                fontSize: 22, // Larger font size for the main heading
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Your Personal Financial Assistant',
              style: GoogleFonts.oswald(
                fontSize: 16, // Smaller font size for the subtitle
                color: Colors.white70,
                fontStyle:
                    FontStyle.italic, // Slightly dimmed color for subtitle
              ),
            ),
          ],
        ),
      ),
      body: width < 600
          ? Column(
              children: [
                Chart(expenses: _listOfExpenses),
                Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Total Expense: PKR ${_totalExpenses.toStringAsFixed(2)}',
                      style: GoogleFonts.oswald(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Expanded(child: mainContent),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Chart(expenses: _listOfExpenses),
                      Card(
                        margin: const EdgeInsets.all(16),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Total Expense: PKR ${_totalExpenses.toStringAsFixed(2)}',
                            style: GoogleFonts.oswald(fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: mainContent),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add Expense',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.exit_to_app),
            label: 'Sign Out',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.picture_as_pdf),
            label: 'Generate PDF',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            _addExpenseOverlay();
          } else if (index == 1) {
            _signOut();
          } else if (index == 2) {
            _generateAndSavePDF();
          }
        },
      ),
    );
  }
}
