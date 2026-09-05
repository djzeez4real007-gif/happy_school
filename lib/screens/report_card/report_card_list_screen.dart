import 'package:flutter/material.dart';
import '../../core/widgets/app_back.dart';

import '../../models/report_card.dart';
import '../../services/report_card_storage.dart';
import 'report_card_screen.dart';

class ReportCardListScreen extends StatefulWidget {
  const ReportCardListScreen({super.key});

  @override
  State<ReportCardListScreen> createState() => _ReportCardListScreenState();
}

class _ReportCardListScreenState extends State<ReportCardListScreen> {
  List<ReportCard> reportCards = [];

  @override
  void initState() {
    super.initState();
    loadReportCards();
  }

  Future<void> loadReportCards() async {
    final data = await ReportCardStorage.getReportCards();

    if (!mounted) return;

    setState(() {
      reportCards = data;
    });
  }

  Future<void> deleteCard(int index) async {
    await ReportCardStorage.deleteReportCard(index);

    if (!mounted) return;

    loadReportCards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBack.leading(context),title: Text("Report Cards (${reportCards.length})")),

      body: reportCards.isEmpty
          ? const Center(
              child: Text(
                "No Report Cards Generated",
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: reportCards.length,
              itemBuilder: (context, index) {
                final card = reportCards[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),

                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: const Icon(Icons.description, color: Colors.blue),
                    ),

                    title: Text(
                      card.studentName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),

                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),

                        Text("${card.className} • ${card.term}"),

                        Text(card.session),

                        const SizedBox(height: 5),

                        Text(
                          "Average: ${card.average.toStringAsFixed(2)}%",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        Text("Grade: ${card.overallGrade}"),

                        Text("Position: ${card.position}"),
                      ],
                    ),

                    isThreeLine: true,

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReportCardScreen(reportCard: card),
                        ),
                      );
                    },

                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == "view") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ReportCardScreen(reportCard: card),
                            ),
                          );
                        }

                        if (value == "delete") {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Delete Report Card"),
                              content: Text(
                                "Delete report card for ${card.studentName}?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Delete"),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            deleteCard(index);
                          }
                        }
                      },

                      itemBuilder: (_) => const [
                        PopupMenuItem(value: "view", child: Text("View")),
                        PopupMenuItem(value: "delete", child: Text("Delete")),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
