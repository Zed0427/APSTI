import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../themes.dart';

class ReportDetailScreen extends StatefulWidget {
  final Map<String, dynamic> report;

  const ReportDetailScreen({
    super.key,
    required this.report,
  });

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  Map<String, dynamic>? animalDetails;
  final ScrollController _scrollController = ScrollController();
  bool showShadow = false;

  @override
  void initState() {
    super.initState();
    _fetchAnimalDetails();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset > 0 && !showShadow) {
      setState(() => showShadow = true);
    } else if (_scrollController.offset <= 0 && showShadow) {
      setState(() => showShadow = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchAnimalDetails() async {
    final animalId = widget.report['animalId'];
    if (animalId != null) {
      final ref = FirebaseDatabase.instance.ref('animals/$animalId');
      final snapshot = await ref.get();
      if (snapshot.exists) {
        setState(() {
          animalDetails = Map<String, dynamic>.from(snapshot.value as Map);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildHeader(),
                _buildContent(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: false,
      pinned: true,
      elevation: showShadow ? 4 : 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.text),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildHeader() {
    final date = widget.report['date'] != null
        ? DateFormat('MMMM dd, yyyy')
            .format(DateTime.parse(widget.report['date']))
        : 'No date';

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.report['type'] ?? 'Unknown Type',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ).animate().fadeIn().slideX(),
          const SizedBox(height: 16),
          Text(
            widget.report['title'] ?? 'Untitled Report',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ).animate().fadeIn().slideX(delay: 200.ms),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                date,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textLight,
                ),
              ),
            ],
          )
        ],
      ),
    ).animate().scale(delay: 100.ms);
  }

  Widget _buildContent() {
    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDescriptionSection(),
          if (widget.report['type'] == 'Necropsy Report') ...[
            _buildAnimatedDivider(),
            _buildAnimalInfoSection(),
            _buildAnimatedDivider(),
            _buildExaminationSection(),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildDescriptionSection() {
    return _buildSectionWithTitle(
      'Description',
      content: widget.report['description'] ?? 'No description available',
    );
  }

  Widget _buildAnimalInfoSection() {
    return _buildSectionWithTitle(
      'Animal Information',
      child: Column(
        children: [
          _buildInfoCard(
            'Animal Details',
            [
              InfoItem('Name', animalDetails?['name'] ?? 'Unknown'),
              InfoItem('Age', widget.report['age']),
              InfoItem('Weight', '${widget.report['weight']} kg'),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Death Information',
            [
              InfoItem('Date', widget.report['dateOfDeath']),
              InfoItem('Time', widget.report['timeOfDeath']),
              InfoItem('Condition', widget.report['bodyCondition']),
              InfoItem('Euthanized',
                  widget.report['wasEuthanized'] == 'true' ? 'Yes' : 'No'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExaminationSection() {
    return _buildSectionWithTitle(
      'Examination Findings',
      child: Column(
        children: [
          _buildInfoCard(
            'Primary Findings',
            [
              InfoItem('Cause of Death', widget.report['causeOfDeath']),
              InfoItem('Post-Mortem', widget.report['postMortemFindings']),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Detailed Analysis',
            [
              InfoItem('Organ Systems', widget.report['organSystemFindings']),
              InfoItem(
                  'Histopathology', widget.report['histopathologyResults']),
              InfoItem('Toxicology', widget.report['toxicologyResults']),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionWithTitle(String title,
      {String? content, Widget? child}) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          if (content != null) ...[
            const SizedBox(height: 16),
            Text(
              content,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColors.text,
                height: 1.5,
              ),
            ),
          ],
          if (child != null) ...[
            const SizedBox(height: 16),
            child,
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<InfoItem> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        item.label,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.value?.toString() ?? 'N/A',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildAnimatedDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      color: Colors.grey[200],
    ).animate().fadeIn().shimmer();
  }
}

class InfoItem {
  final String label;
  final dynamic value;

  InfoItem(this.label, this.value);
}
