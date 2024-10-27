import 'package:flutter/material.dart';

class BudgetSection {
  final String name;
  final bool isIncome;
  List<Map<String, dynamic>> subsections;

  BudgetSection({
    required this.name,
    required this.isIncome,
    this.subsections = const [],
  });
}

class BudgetScreen extends StatefulWidget {
  @override
  _BudgetScreenState createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  bool isPlannedSelected = true;
  Map<String, BudgetSection> plannedSections = {
    'Monthly Income': BudgetSection(
      name: 'Monthly Income',
      isIncome: true,
      subsections: [
        {'name': 'Paycheck 1', 'amount': 2000},
        {'name': 'Paycheck 2', 'amount': 1500},
      ],
    ),
    'Housing': BudgetSection(
      name: 'Housing',
      isIncome: false,
      subsections: [
        {'name': 'Rent', 'amount': 800},
        {'name': 'Utilities', 'amount': 100},
      ],
    ),
  };

  Map<String, BudgetSection> spentSections = {
    'Monthly Income': BudgetSection(
      name: 'Monthly Income',
      isIncome: true,
      subsections: [
        {'name': 'Paycheck 1', 'amount': 500},
      ],
    ),
    'Housing': BudgetSection(
      name: 'Housing',
      isIncome: false,
      subsections: [
        {'name': 'Rent', 'amount': 800},
        {'name': 'Utilities', 'amount': 150},
      ],
    ),
  };

  void _addNewSection() {
    TextEditingController sectionNameController = TextEditingController();
    bool isIncome = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Color(0xFF282A36),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              title: Text(
                'Add New Section',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Gayathri',
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: sectionNameController,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Gayathri',
                    ),
                    decoration: InputDecoration(
                      hintText: 'Section Name',
                      hintStyle: TextStyle(
                        color: Colors.white54,
                        fontFamily: 'Gayathri',
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Section Type:',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Gayathri',
                        ),
                      ),
                      SizedBox(width: 16),
                      Switch(
                        value: isIncome,
                        onChanged: (value) {
                          setDialogState(() {
                            isIncome = value;
                          });
                        },
                        activeColor: Color(0xFF50FA7B),
                      ),
                      Text(
                        isIncome ? 'Income' : 'Expense',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Gayathri',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (sectionNameController.text.isNotEmpty) {
                      setState(() {
                        String sectionName = sectionNameController.text;
                        plannedSections[sectionName] = BudgetSection(
                          name: sectionName,
                          isIncome: isIncome,
                          subsections: [],
                        );
                        spentSections[sectionName] = BudgetSection(
                          name: sectionName,
                          isIncome: isIncome,
                          subsections: [],
                        );
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    'Add',
                    style: TextStyle(
                      color: Color(0xFF50FA7B),
                      fontFamily: 'Gayathri',
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool isOnBudget() {
    double totalPlannedIncome = 0;
    double totalPlannedExpenses = 0;
    double totalSpentIncome = 0;
    double totalSpentExpenses = 0;

    plannedSections.forEach((key, section) {
      double sectionTotal = section.subsections.fold(
        0.0,
            (sum, item) => sum + (item['amount'] as num),
      );
      if (section.isIncome) {
        totalPlannedIncome += sectionTotal;
      } else {
        totalPlannedExpenses += sectionTotal;
      }
    });

    spentSections.forEach((key, section) {
      double sectionTotal = section.subsections.fold(
        0.0,
            (sum, item) => sum + (item['amount'] as num),
      );
      if (section.isIncome) {
        totalSpentIncome += sectionTotal;
      } else {
        totalSpentExpenses += sectionTotal;
      }
    });

    return totalSpentExpenses <= totalPlannedIncome;
  }

  void _addSubsection(String sectionTitle, bool isPlanned) {
    TextEditingController nameController = TextEditingController();
    TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF282A36),
          title: Text(
            'Add Subsection',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Gayathri',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Gayathri',
                ),
                decoration: InputDecoration(
                  hintText: 'Name',
                  hintStyle: TextStyle(
                    color: Colors.white54,
                    fontFamily: 'Gayathri',
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Gayathri',
                ),
                decoration: InputDecoration(
                  hintText: 'Amount',
                  hintStyle: TextStyle(
                    color: Colors.white54,
                    fontFamily: 'Gayathri',
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    amountController.text.isNotEmpty) {
                  setState(() {
                    Map<String, BudgetSection> targetSections = isPlanned
                        ? plannedSections
                        : spentSections;
                    targetSections[sectionTitle]?.subsections.add({
                      'name': nameController.text,
                      'amount': double.parse(amountController.text),
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(
                'Add',
                style: TextStyle(
                  color: Color(0xFF50FA7B),
                  fontFamily: 'Gayathri',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionCard(String sectionTitle, BudgetSection section,
      bool isPlanned) {
    double totalAmount = section.subsections.fold(
      0.0,
          (sum, item) => sum + (item['amount'] as num),
    );

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Color(0xFF44475A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                sectionTitle,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'Gayathri',
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.add_circle_outline,
                color: Color(0xFF50FA7B),
              ),
              onPressed: () => _addSubsection(sectionTitle, isPlanned),
            ),
          ],
        ),
        subtitle: Text(
          '${section.isIncome ? "+" : "-"}\$$totalAmount',
          style: TextStyle(
            color: section.isIncome ? Color(0xFF50FA7B) : Color(0xFFFF79C6),
            fontSize: 16,
            fontFamily: 'Gayathri',
          ),
        ),
        children: section.subsections.map((subsection) {
          return ListTile(
            title: Text(
              subsection['name'],
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Gayathri',
              ),
            ),
            trailing: Text(
              '${section.isIncome ? "+" : "-"}\$${subsection['amount']}',
              style: TextStyle(
                color: section.isIncome ? Color(0xFF50FA7B) : Color(0xFFFF79C6),
                fontFamily: 'Gayathri',
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF282A36),
      appBar: AppBar(
        backgroundColor: Color(0xFF44475A),
        title: Text(
          'Budget',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Gayathri',
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                plannedSections.clear();
                spentSections.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              isPlannedSelected
                  ? 'Planned Budget'
                  : isOnBudget()
                  ? 'On Budget ✓'
                  : 'Over Budget ⚠️',
              style: TextStyle(
                color: isPlannedSelected
                    ? Colors.white
                    : isOnBudget()
                    ? Color(0xFF50FA7B)
                    : Color(0xFFFF79C6),
                fontSize: 24,
                fontFamily: 'Gayathri',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Color(0xFF44475A),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isPlannedSelected = true),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isPlannedSelected ? Color(0xFF50FA7B) : Colors
                            .transparent,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        'Planned',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isPlannedSelected ? Color(0xFF282A36) : Colors
                              .white,
                          fontFamily: 'Gayathri',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isPlannedSelected = false),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !isPlannedSelected ? Color(0xFF50FA7B) : Colors
                            .transparent,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        'Spent',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: !isPlannedSelected ? Color(0xFF282A36) : Colors
                              .white,
                          fontFamily: 'Gayathri',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: (isPlannedSelected ? plannedSections : spentSections)
                  .length,
              itemBuilder: (context, index) {
                String sectionTitle = (isPlannedSelected
                    ? plannedSections
                    : spentSections)
                    .keys
                    .elementAt(index);
                BudgetSection section =
                (isPlannedSelected
                    ? plannedSections
                    : spentSections)[sectionTitle]!;
                return _buildSectionCard(
                    sectionTitle, section, isPlannedSelected);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF50FA7B),
        onPressed: _addNewSection,
        child: Icon(Icons.add, color: Color(0xFF282A36)),
      ),
    );
  }
}