import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../provider/task_provider.dart';
import '../provider/app_provider.dart';
import '../widgets/web_sidebar.dart';
import '../widgets/mobile_bottom_nav.dart';
import 'add_project_screen.dart';
import 'task_detail_screen.dart';
import '../widgets/quick_add_task_dialog.dart';
import '../widgets/quick_edit_task_dialog.dart';
import '../widgets/app_popup.dart';
import '../services/calendar_import_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _miniMonth = DateTime.now();
  String _viewMode = 'week';
  final ScrollController _scroll = ScrollController();

  // Filter states
  List<String> _selectedProjectIds = [];
  List<String> _selectedCategories = [];
  bool _showFilters = true;

  // GitHub Style Colors
  static const Color ghDarkBg = Color(0xFF0D1117);
  static const Color ghDarkCard = Color(0xFF161B22);
  static const Color ghDarkBorder = Color(0xFF30363D);
  static const Color ghDarkText = Color(0xFFC9D1D9);
  static const Color ghDarkSubText = Color(0xFF8B949E);

  static const Color ghLightBg = Color(0xFFF6F8FA);
  static const Color ghLightCard = Color(0xFFFFFFFF);
  static const Color ghLightBorder = Color(0xFFD0D7DE);
  static const Color ghLightText = Color(0xFF24292F);
  static const Color ghLightSubText = Color(0xFF57606A);

  static const Color ghBlue = Color(0xFF58A6FF);
  static const Color ghGreen = Color(0xFF3FB950);
  static const Color ghOrange = Color(0xFFD29922);
  static const Color ghPurple = Color(0xFFA371F7);

  static const double _hh = 70.0; // Increased height for larger text

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final h = DateTime.now().hour;
      if (_scroll.hasClients) {
        _scroll.animateTo(
          (h - 1).clamp(0, 22) * _hh,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool _same(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    try {
      return a.year == b.year && a.month == b.month && a.day == b.day;
    } catch (e) {
      return false;
    }
  }

  List<DateTime> _weekOf(DateTime d) {
    final mon = d.subtract(Duration(days: d.weekday - 1));
    return List.generate(7, (i) => mon.add(Duration(days: i)));
  }

  List<Task> _forDay(DateTime d, List<Task> all) =>
      all.where((t) => _same(t.due_day, d)).toList();

  Color _taskColor(int p) => p == 3
      ? Colors.redAccent
      : p == 2
          ? ghOrange
          : ghBlue;

  String _fmtHM(DateTime? d) => d == null ? "" : DateFormat('HH:mm').format(d);
  String _fmtDHM(DateTime? d) =>
      d == null ? "" : DateFormat('dd/MM/yyyy HH:mm').format(d);

  double _nowY() {
    final now = DateTime.now();
    return now.hour * _hh + now.minute * _hh / 60;
  }

  double _taskY(Task t) => t.due_day.hour * _hh + t.due_day.minute * _hh / 60;

  void _prev() {
    setState(() {
      if (_viewMode == 'day') {
        _selectedDay = _selectedDay.subtract(const Duration(days: 1));
      } else if (_viewMode == 'week') {
        _selectedDay = _selectedDay.subtract(const Duration(days: 7));
      } else if (_viewMode == 'month') {
        _miniMonth = DateTime(_miniMonth.year, _miniMonth.month - 1);
      } else if (_viewMode == 'year') {
        _miniMonth = DateTime(_miniMonth.year - 1, _miniMonth.month);
      }
      if (_viewMode != 'month' && _viewMode != 'year') {
        _miniMonth = _selectedDay;
      }
    });
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _next() {
    setState(() {
      if (_viewMode == 'day') {
        _selectedDay = _selectedDay.add(const Duration(days: 1));
      } else if (_viewMode == 'week') {
        _selectedDay = _selectedDay.add(const Duration(days: 7));
      } else if (_viewMode == 'month') {
        _miniMonth = DateTime(_miniMonth.year, _miniMonth.month + 1);
      } else if (_viewMode == 'year') {
        _miniMonth = DateTime(_miniMonth.year + 1, _miniMonth.month);
      }
      if (_viewMode != 'month' && _viewMode != 'year') {
        _miniMonth = _selectedDay;
      }
    });
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final isDark = appProvider.themeMode == ThemeMode.dark;
    final isWeb = MediaQuery.of(context).size.width > 900;

    final bgColor = isDark ? ghDarkBg : ghLightBg;
    final textColor = isDark ? ghDarkText : ghLightText;
    final borderColor = isDark ? ghDarkBorder : ghLightBorder;

    final provider = context.watch<TaskProvider>();
    final allTasks = provider.tasks;

    // Apply filters
    final filteredTasks = allTasks.where((t) {
      bool projectMatch = _selectedProjectIds.isEmpty ||
          _selectedProjectIds.contains(t.project_id);
      bool categoryMatch = _selectedCategories.isEmpty ||
          _selectedCategories.contains(t.category);
      return projectMatch && categoryMatch;
    }).toList();

    return Scaffold(
      backgroundColor: bgColor,
      bottomNavigationBar:
          isWeb ? null : MobileBottomNav(currentRoute: 'calendar'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => QuickAddTaskDialog(initialDate: _selectedDay),
        ),
        backgroundColor: ghGreen,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: Row(
        children: [
          if (isWeb) const WebSidebar(currentRoute: 'calendar'),
          Expanded(
            child: Column(
              children: [
                _buildHeader(isDark, isWeb, textColor, borderColor),
                Expanded(
                  child: Row(
                    children: [
                      if (isWeb)
                        _buildLeftPanel(
                          isDark,
                          borderColor,
                          textColor,
                          provider,
                        ),
                      Expanded(
                        child: _buildMainView(
                          isDark,
                          filteredTasks,
                          borderColor,
                          textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    bool isDark,
    bool isWeb,
    Color textColor,
    Color borderColor,
  ) {
    String label;
    if (_viewMode == 'month') {
      label = "Tháng ${DateFormat('MM/yyyy').format(_miniMonth)}";
    } else if (_viewMode == 'year') {
      label = "Năm ${_miniMonth.year}";
    } else {
      label = "Tháng ${DateFormat('MM/yyyy').format(_selectedDay)}";
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 20 : 8,
        vertical: isWeb ? 12 : 6,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Builder(
        builder: (context) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (isWeb)
                PopupMenuButton<String>(
                  icon:
                      Icon(Icons.menu, color: textColor, size: isWeb ? 24 : 22),
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'day' ||
                        value == 'week' ||
                        value == 'month' ||
                        value == 'year') {
                      setState(() => _viewMode = value);
                    } else if (value == 'toggle_filters') {
                      setState(() => _showFilters = !_showFilters);
                    } else if (value == 'clear_filters') {
                      setState(() {
                        _selectedProjectIds = [];
                        _selectedCategories = [];
                      });
                    } else if (value.startsWith('category_')) {
                      final category = value.replaceFirst('category_', '');
                      setState(() {
                        if (_selectedCategories.contains(category)) {
                          _selectedCategories.remove(category);
                        } else {
                          _selectedCategories.add(category);
                        }
                      });
                    } else if (value.startsWith('project_')) {
                      final projectId = value.replaceFirst('project_', '');
                      setState(() {
                        if (_selectedProjectIds.contains(projectId)) {
                          _selectedProjectIds.remove(projectId);
                        } else {
                          _selectedProjectIds.add(projectId);
                        }
                      });
                    }
                  },
                  itemBuilder: (context) {
                    final categories = [
                      'Công việc',
                      'Cá nhân',
                      'Học tập',
                      'Khác'
                    ];
                    final provider =
                        Provider.of<TaskProvider>(context, listen: false);
                    final projects = provider.projects;

                    return [
                      const PopupMenuItem(
                        value: 'day',
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 18),
                            SizedBox(width: 12),
                            Text('Xem theo ngày'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'week',
                        child: Row(
                          children: [
                            Icon(Icons.calendar_view_week, size: 18),
                            SizedBox(width: 12),
                            Text('Xem theo tuần'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'month',
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month, size: 18),
                            SizedBox(width: 12),
                            Text('Xem theo tháng'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'year',
                        child: Row(
                          children: [
                            Icon(Icons.calendar_view_month, size: 18),
                            SizedBox(width: 12),
                            Text('Xem theo năm'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        enabled: false,
                        child: Text(
                          'Lọc theo danh mục',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      ...categories.map((category) => PopupMenuItem(
                            value: 'category_$category',
                            child: Row(
                              children: [
                                Icon(
                                  _selectedCategories.contains(category)
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  size: 18,
                                ),
                                SizedBox(width: 12),
                                Text(category),
                              ],
                            ),
                          )),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        enabled: false,
                        child: Text(
                          'Lọc theo dự án',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      ...projects.map((project) => PopupMenuItem(
                            value: 'project_${project.project_id}',
                            child: Row(
                              children: [
                                Icon(
                                  _selectedProjectIds
                                          .contains(project.project_id)
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  size: 18,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    project.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'clear_filters',
                        child: Row(
                          children: [
                            Icon(Icons.clear_all, size: 18),
                            SizedBox(width: 12),
                            Text('Xóa bộ lọc'),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              if (!isWeb)
                IconButton(
                  icon: Icon(Icons.arrow_back, color: textColor, size: 22),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.pop(context),
                ),
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: isWeb ? 18 : 14,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_left, size: isWeb ? 24 : 22),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onPressed: _prev,
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, size: isWeb ? 24 : 22),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onPressed: _next,
              ),
              IconButton(
                icon: const Icon(Icons.upload),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onPressed: () async {
                  final events = await CalendarImportService.importICS();
                  if (events.isEmpty) {
                    if (mounted) {
                      AppPopup.show(
                        context,
                        title: 'Import thất bại',
                        message:
                            'Không thể import file ICS. Vui lòng kiểm tra lại.',
                        color: ghOrange,
                        icon: Icons.error,
                      );
                    }
                    return;
                  }

                  if (!mounted) return;
                  final provider =
                      Provider.of<TaskProvider>(context, listen: false);
                  int importedCount = 0;
                  int skippedCount = 0;

                  for (var event in events) {
                    final start = event['start'] as DateTime?;
                    final end = event['end'] as DateTime?;
                    if (start == null || end == null) {
                      skippedCount++;
                      continue;
                    }

                    final duration = end.difference(start).inMinutes;

                    final task = Task(
                      task_id: const Uuid().v4(),
                      user_id: 'current_user',
                      title: event['title'] as String? ?? 'Không có tiêu đề',
                      description: event['description'] as String? ?? '',
                      due_day: start,
                      deadline: end,
                      duration: duration,
                      priority: event['priority'] as int? ?? 1,
                      status: 'pending',
                      progress: 0,
                      category: event['category'] as String? ?? 'Công việc',
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                      isSynced: false,
                    );

                    await provider.addTask(task);
                    importedCount++;
                  }

                  if (mounted) {
                    String message =
                        'Đã import thành công $importedCount công việc từ lịch';
                    if (skippedCount > 0) {
                      message +=
                          '\n(Bỏ qua $skippedCount công việc không hợp lệ)';
                    }

                    AppPopup.show(
                      context,
                      title: 'Đã import',
                      message: message,
                      color: ghGreen,
                      icon: Icons.check_circle,
                    );
                  }
                },
              ),
              if (!isWeb)
                PopupMenuButton<String>(
                  icon: Icon(Icons.menu, color: textColor, size: 22),
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    if (value == 'day' ||
                        value == 'week' ||
                        value == 'month' ||
                        value == 'year') {
                      setState(() => _viewMode = value);
                    } else if (value == 'toggle_filters') {
                      setState(() => _showFilters = !_showFilters);
                    } else if (value == 'clear_filters') {
                      setState(() {
                        _selectedProjectIds = [];
                        _selectedCategories = [];
                      });
                    } else if (value.startsWith('category_')) {
                      final category = value.replaceFirst('category_', '');
                      setState(() {
                        if (_selectedCategories.contains(category)) {
                          _selectedCategories.remove(category);
                        } else {
                          _selectedCategories.add(category);
                        }
                      });
                    } else if (value.startsWith('project_')) {
                      final projectId = value.replaceFirst('project_', '');
                      setState(() {
                        if (_selectedProjectIds.contains(projectId)) {
                          _selectedProjectIds.remove(projectId);
                        } else {
                          _selectedProjectIds.add(projectId);
                        }
                      });
                    }
                  },
                  itemBuilder: (context) {
                    final categories = [
                      'Công việc',
                      'Cá nhân',
                      'Học tập',
                      'Khác'
                    ];
                    final provider =
                        Provider.of<TaskProvider>(context, listen: false);
                    final projects = provider.projects;

                    return [
                      const PopupMenuItem(
                        value: 'day',
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 18),
                            SizedBox(width: 12),
                            Text('Xem theo ngày'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'week',
                        child: Row(
                          children: [
                            Icon(Icons.calendar_view_week, size: 18),
                            SizedBox(width: 12),
                            Text('Xem theo tuần'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'month',
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month, size: 18),
                            SizedBox(width: 12),
                            Text('Xem theo tháng'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'year',
                        child: Row(
                          children: [
                            Icon(Icons.calendar_view_month, size: 18),
                            SizedBox(width: 12),
                            Text('Xem theo năm'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        enabled: false,
                        child: Text(
                          'Lọc theo danh mục',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      ...categories.map((category) => PopupMenuItem(
                            value: 'category_$category',
                            child: Row(
                              children: [
                                Icon(
                                  _selectedCategories.contains(category)
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  size: 18,
                                ),
                                SizedBox(width: 12),
                                Text(category),
                              ],
                            ),
                          )),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        enabled: false,
                        child: Text(
                          'Lọc theo dự án',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      ...projects.map((project) => PopupMenuItem(
                            value: 'project_${project.project_id}',
                            child: Row(
                              children: [
                                Icon(
                                  _selectedProjectIds
                                          .contains(project.project_id)
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  size: 18,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    project.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'clear_filters',
                        child: Row(
                          children: [
                            Icon(Icons.clear_all, size: 18),
                            SizedBox(width: 12),
                            Text('Xóa bộ lọc'),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeftPanel(
    bool isDark,
    Color borderColor,
    Color textColor,
    TaskProvider provider,
  ) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _buildMiniCalendar(isDark),
            ),
            const Divider(height: 1),
            _buildFilterSection(
              "DỰ ÁN CỦA TÔI",
              provider.projects
                  .map(
                    (p) => {
                      'id': p.project_id,
                      'label': p.name,
                      'color': ghBlue,
                    },
                  )
                  .toList(),
              _selectedProjectIds,
              (id) {
                setState(() {
                  if (_selectedProjectIds.contains(id)) {
                    _selectedProjectIds.remove(id);
                  } else {
                    _selectedProjectIds.add(id);
                  }
                });
              },
              isDark,
            ),
            const Divider(height: 1),
            _buildFilterSection(
              "DANH MỤC",
              [
                {'id': 'Công việc', 'label': 'Công việc', 'color': ghOrange},
                {'id': 'Cá nhân', 'label': 'Cá nhân', 'color': ghGreen},
                {'id': 'Học tập', 'label': 'Học tập', 'color': ghPurple},
              ],
              _selectedCategories,
              (id) {
                setState(() {
                  if (_selectedCategories.contains(id)) {
                    _selectedCategories.remove(id);
                  } else {
                    _selectedCategories.add(id);
                  }
                });
              },
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(
    String title,
    List<Map<String, dynamic>> items,
    List<String> selectedList,
    Function(String) onToggle,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isDark ? ghDarkSubText : ghLightSubText,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              if (title == "DỰ ÁN CỦA TÔI")
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const AddProjectScreen(),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
        ...items.map((item) {
          bool isSelected = selectedList.contains(item['id']);
          return InkWell(
            onTap: () => onToggle(item['id']),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? item['color'] : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? item['color']
                            : (isDark ? ghDarkBorder : ghLightBorder),
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  Expanded(
                    child: Text(
                      item['label'],
                      style: TextStyle(
                        color: isDark ? ghDarkText : ghLightText,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildMiniCalendar(bool isDark) {
    final first = DateTime(_miniMonth.year, _miniMonth.month, 1);
    final offset = first.weekday - 1;
    final days = DateUtils.getDaysInMonth(_miniMonth.year, _miniMonth.month);
    final now = DateTime.now();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Tháng ${_miniMonth.month}/${_miniMonth.year}",
              style: TextStyle(
                color: isDark ? ghDarkText : ghLightText,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
          ),
          itemCount: offset + days,
          itemBuilder: (_, i) {
            if (i < offset) return const SizedBox();
            final day = DateTime(
              _miniMonth.year,
              _miniMonth.month,
              i - offset + 1,
            );
            final isToday = _same(day, now);
            final isSel = _same(day, _selectedDay);
            return GestureDetector(
              onTap: () => setState(() {
                _selectedDay = day;
                _viewMode = 'day';
              }),
              child: Center(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isToday
                        ? ghGreen
                        : (isSel
                            ? ghBlue.withValues(alpha: 0.2)
                            : Colors.transparent),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isToday
                          ? Colors.white
                          : (isSel
                              ? ghBlue
                              : (isDark ? ghDarkSubText : ghLightSubText)),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMainView(
    bool isDark,
    List<Task> tasks,
    Color borderColor,
    Color textColor,
  ) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.3, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(_viewMode),
        child: switch (_viewMode) {
          'day' => _buildDayTimeline(isDark, tasks, borderColor, textColor),
          'month' => _buildMonthGrid(isDark, tasks, borderColor, textColor),
          _ => _buildWeekTimeline(isDark, tasks, borderColor, textColor),
        },
      ),
    );
  }

  Widget _buildDayTimeline(
    bool isDark,
    List<Task> tasks,
    Color borderColor,
    Color textColor,
  ) {
    return Column(
      children: [
        _buildTimelineHeader([_selectedDay], isDark, textColor, borderColor),
        Expanded(
          child: SingleChildScrollView(
            controller: _scroll,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: _hh * 24,
              ),
              child: SizedBox(
                height: _hh * 24,
                child: Row(
                  children: [
                    _buildTimeGutter(isDark),
                    Expanded(
                      child: _buildDayColumn(
                        _selectedDay,
                        tasks,
                        isDark,
                        borderColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekTimeline(
    bool isDark,
    List<Task> tasks,
    Color borderColor,
    Color textColor,
  ) {
    final days = _weekOf(_selectedDay);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTimelineHeader(days, isDark, textColor, borderColor),
        Expanded(
          child: SingleChildScrollView(
            controller: _scroll,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: _hh * 24,
              ),
              child: SizedBox(
                height: _hh * 24,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTimeGutter(isDark),
                    ...days.map(
                      (d) => Expanded(
                        child: _buildDayColumn(d, tasks, isDark, borderColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineHeader(
    List<DateTime> days,
    bool isDark,
    Color textColor,
    Color borderColor,
  ) {
    final now = DateTime.now();
    final weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return Container(
      decoration: BoxDecoration(
        color: isDark ? ghDarkCard : ghLightCard,
        border: Border(bottom: BorderSide(color: borderColor, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const SizedBox(width: 70),
          ...days.map((d) {
            final isToday = _same(d, now);
            return Expanded(
              child: Column(
                children: [
                  Text(
                    weekdays[d.weekday - 1],
                    style: TextStyle(
                      fontSize: 13,
                      color: isToday
                          ? ghGreen
                          : (isDark ? ghDarkSubText : ghLightSubText),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: isToday
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [ghGreen, ghGreen.withValues(alpha: 0.8)],
                            )
                          : null,
                      color:
                          isToday ? null : (isDark ? ghDarkCard : ghLightCard),
                      shape: BoxShape.circle,
                      border: isToday
                          ? null
                          : Border.all(color: borderColor, width: 1),
                      boxShadow: isToday
                          ? [
                              BoxShadow(
                                color: ghGreen.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${d.day}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isToday ? Colors.white : textColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimeGutter(bool isDark) {
    return Container(
      width: 70,
      padding: const EdgeInsets.only(right: 12),
      child: Stack(
        children: List.generate(
          48, // 24 hours * 2 (30-minute intervals)
          (i) => Positioned(
            top: i * (_hh / 2) - 8,
            left: 0,
            right: 0,
            child: Text(
              '${(i ~/ 2).toString().padLeft(2, '0')}:${(i % 2 == 0 ? '00' : '30')}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? ghDarkSubText : ghLightSubText,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }

  final Map<DateTime, GlobalKey> _columnKeys = {};

  Widget _buildDayColumn(
    DateTime day,
    List<Task> tasks,
    bool isDark,
    Color borderColor,
  ) {
    _columnKeys[day] ??= GlobalKey();

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) async {
        final context = _columnKeys[day]?.currentContext;
        if (context == null) return;

        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox == null || !renderBox.hasSize) return;

        final localOffset = renderBox.globalToLocal(details.offset);

        // Calculate new hour and minute
        double rawHour = localOffset.dy / _hh;
        int hour = rawHour.floor().clamp(0, 23);
        int minute = (((localOffset.dy % _hh) / _hh * 60) / 15).round() * 15;
        if (minute == 60) {
          hour++;
          minute = 0;
        }
        if (hour > 23) {
          hour = 23;
          minute = 45;
        }

        final newTaskTime = DateTime(
          day.year,
          day.month,
          day.day,
          hour,
          minute,
        );
        final task = details.data;

        // Update task time
        task.due_day = newTaskTime;
        task.deadline = newTaskTime.add(Duration(minutes: task.duration));
        task.updatedAt = DateTime.now();
        task.isSynced = false;

        if (!mounted) return;
        await Provider.of<TaskProvider>(
          context,
          listen: false,
        ).updateTask(task);
        if (!mounted) return;
        AppPopup.show(
          context,
          title: 'Đã cập nhật',
          message:
              "Đã chuyển '${task.title}' sang ${_fmtHM(newTaskTime)} ngày ${day.day}/${day.month}",
          color: ghBlue,
          icon: Icons.event_available,
        );
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          key: _columnKeys[day],
          height: _hh * 24,
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: borderColor, width: 1)),
          ),
          child: Stack(
            children: [
              ...List.generate(
                48, // 24 hours * 2 (30-minute intervals)
                (i) => Positioned(
                  top: i * (_hh / 2),
                  left: 0,
                  right: 0,
                  height: _hh / 2,
                  child: GestureDetector(
                    onTap: () => _showQuickAddTask(day, i ~/ 2, (i % 2) * 30),
                    child: Container(
                      color: Colors.transparent,
                      child: Divider(
                        height: 1,
                        color: borderColor,
                        thickness: 1,
                      ),
                    ),
                  ),
                ),
              ),
              if (_same(day, DateTime.now()))
                Positioned(
                  top: _nowY(),
                  left: 0,
                  right: 0,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: ghBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 2,
                          color: ghBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ..._forDay(
                day,
                tasks,
              ).map((task) => _buildTaskBlock(task, isDark)),
              if (candidateData.isNotEmpty)
                Positioned.fill(
                  child: Container(color: ghBlue.withValues(alpha: 0.05)),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskBlock(Task task, bool isDark) {
    final color = _taskColor(task.priority);
    final top = _taskY(task);
    final currentDuration =
        _resizingTask == task ? _tempDuration ?? task.duration : task.duration;
    final currentH = currentDuration / 60 * _hh;

    final content = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: isDark ? 0.25 : 0.15),
            color.withValues(alpha: isDark ? 0.1 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: TextStyle(
              color: isDark ? ghDarkText : ghLightText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _fmtDHM(task.due_day),
            style: TextStyle(
              color: isDark ? ghDarkSubText : ghLightSubText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      top: top,
      left: 2,
      right: 2,
      height: currentH,
      child: Stack(
        children: [
          Draggable<Task>(
            data: task,
            feedback: Material(
              elevation: 12,
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.5 : 0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(left: BorderSide(color: color, width: 5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(10),
                child: SizedBox(
                  width: (() {
                    final context = _columnKeys[task.due_day]?.currentContext;
                    if (context == null) return 150.0;
                    final renderBox = context.findRenderObject() as RenderBox?;
                    if (renderBox == null || !renderBox.hasSize) return 150.0;
                    return renderBox.size.width;
                  })(),
                  height: currentH,
                  child: content,
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.1 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(left: BorderSide(color: color, width: 5)),
                ),
                child: content,
              ),
            ),
            onDragStarted: () {
              try {
                Feedback.forLongPress(context);
              } catch (_) {}
            },
            child: AnimatedScale(
              scale: _resizingTask == task ? 1.02 : 1.0,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              child: InkWell(
                onTap: () => _openTask(task),
                borderRadius: BorderRadius.circular(8),
                child: content,
              ),
            ),
          ),
          // Resize handle ở cạnh dưới
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 12,
            child: GestureDetector(
              onVerticalDragStart: (details) {
                setState(() {
                  _resizingTask = task;
                  _resizeStartY = details.globalPosition.dy;
                  _resizeStartDuration = task.duration;
                });
                try {
                  Feedback.forLongPress(context);
                } catch (_) {}
              },
              onVerticalDragUpdate: (details) {
                if (_resizingTask == task) {
                  final deltaY = details.globalPosition.dy - _resizeStartY;
                  final deltaMinutes = (deltaY / _hh * 60).round();
                  final newDuration =
                      (_resizeStartDuration + deltaMinutes).clamp(15, 480);

                  setState(() {
                    _tempDuration = newDuration;
                  });
                }
              },
              onVerticalDragEnd: (details) async {
                if (_resizingTask == task && _tempDuration != null) {
                  final newDuration = _tempDuration!;

                  setState(() {
                    _resizingTask = null;
                    _tempDuration = null;
                  });

                  // Cập nhật task
                  task.duration = newDuration;
                  task.deadline = task.due_day.add(
                    Duration(minutes: newDuration),
                  );
                  task.updatedAt = DateTime.now();
                  task.isSynced = false;

                  await Provider.of<TaskProvider>(
                    context,
                    listen: false,
                  ).updateTask(task);

                  if (mounted) {
                    AppPopup.show(
                      context,
                      title: 'Đã cập nhật',
                      message:
                          "Đã thay đổi thời lượng '${task.title}' thành $newDuration phút",
                      color: ghGreen,
                      icon: Icons.access_time,
                    );
                  }
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: _resizingTask == task
                      ? color.withValues(alpha: 0.7)
                      : color.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.only(
                    bottomLeft: const Radius.circular(8),
                    bottomRight: const Radius.circular(8),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.drag_handle,
                    color: Colors.white,
                    size: _resizingTask == task ? 18 : 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Task? _resizingTask;
  double _resizeStartY = 0;
  int _resizeStartDuration = 0;
  int? _tempDuration;

  void _showQuickAddTask(DateTime day, int hour, int minute) {
    final selectedTime = DateTime(day.year, day.month, day.day, hour, minute);
    showDialog(
      context: context,
      builder: (context) => QuickAddTaskDialog(initialDate: selectedTime),
    );
  }

  void _openTask(Task task) {
    if (task.project_id != null && task.project_id!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => QuickEditTaskDialog(task: task),
    );
  }

  Widget _buildMonthGrid(
    bool isDark,
    List<Task> tasks,
    Color borderColor,
    Color textColor,
  ) {
    final first = DateTime(_miniMonth.year, _miniMonth.month, 1);
    final offset = first.weekday - 1;
    final daysCount = DateUtils.getDaysInMonth(
      _miniMonth.year,
      _miniMonth.month,
    );
    final rows = ((offset + daysCount) / 7).ceil();
    final now = DateTime.now();
    final weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: weekdays
                .map(
                  (d) => Expanded(
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? ghDarkSubText : ghLightSubText,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.75,
            ),
            itemCount: rows * 7,
            itemBuilder: (_, i) {
              final dayNum = i - offset + 1;
              if (dayNum < 1 || dayNum > daysCount) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor, width: 0.2),
                  ),
                );
              }
              final day = DateTime(_miniMonth.year, _miniMonth.month, dayNum);
              final dayTasks = _forDay(day, tasks);
              final isToday = _same(day, now);
              return InkWell(
                onTap: () => setState(() {
                  _selectedDay = day;
                  _viewMode = 'day';
                }),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor, width: 0.2),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: isToday ? ghGreen : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$dayNum',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isToday ? Colors.white : textColor,
                            ),
                          ),
                        ),
                      ),
                      ...dayTasks.take(3).map(
                            (t) => Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _taskColor(t.priority)
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                t.title,
                                style: TextStyle(
                                  color: isDark ? ghDarkText : ghLightText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      if (dayTasks.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '+${dayTasks.length - 3} nữa',
                            style: TextStyle(
                              fontSize: 10,
                              color: ghBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
