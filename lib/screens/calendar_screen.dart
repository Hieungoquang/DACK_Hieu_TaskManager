import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../models/task_model.dart';
import '../models/task_category_model.dart';
import '../provider/task_provider.dart';
import '../provider/app_provider.dart';
import '../widgets/web_sidebar.dart';
import '../widgets/mobile_bottom_nav.dart';
import 'task_detail_screen.dart';
import '../widgets/quick_add_task_dialog.dart';
import '../widgets/quick_edit_task_dialog.dart';
import '../widgets/app_popup.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDay = DateTime.now();
  String _viewMode = 'week';
  final CalendarController _calendarController = CalendarController();
  late final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showFilterPanel = true; // toggle panel lọc (chỉ dùng cho web)

  // Filter states: Checked means visible
  List<String> _selectedProjectIds = [];
  List<String> _selectedCategoryIds = [];
  bool _showUncategorized = true;

  // GitHub Style Colors
  static const Color ghDarkBg = Color(0xFF0D1117);
  static const Color ghDarkCard = Color(0xFF161B22);
  static const Color ghDarkBorder = Color(0xFF30363D);
  static const Color ghDarkText = Color(0xFFC9D1D9);
  static const Color ghDarkSubText = Color(0xFF8B949E);

  static const Color ghLightBg = Color(0xFFF6F8FA);
  static const Color ghLightBorder = Color(0xFFD0D7DE);
  static const Color ghLightText = Color(0xFF24292F);
  static const Color ghBlue = Color(0xFF58A6FF);
  static const Color ghGreen = Color(0xFF3FB950);
  @override
  void initState() {
    super.initState();
    _calendarController.view = CalendarView.week;
    _calendarController.displayDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TaskProvider>(context, listen: false);
      setState(() {
        _selectedProjectIds =
            provider.projects.map((p) => p.project_id).toList();
        _selectedCategoryIds = provider.categories.map((c) => c.id).toList();
      });
    });
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<TaskProvider>(context, listen: false);
    final currentProjectIds =
        provider.projects.map((p) => p.project_id).toSet();
    final currentCategoryIds = provider.categories.map((c) => c.id).toSet();

    // Auto-select newly added projects/categories
    final newProjectIds =
        currentProjectIds.difference(_selectedProjectIds.toSet());
    final newCategoryIds =
        currentCategoryIds.difference(_selectedCategoryIds.toSet());

    if (newProjectIds.isNotEmpty || newCategoryIds.isNotEmpty) {
      setState(() {
        _selectedProjectIds.addAll(newProjectIds);
        _selectedCategoryIds.addAll(newCategoryIds);
      });
    }
  }

  void _prev() {
    setState(() {
      if (_viewMode == 'day') {
        _selectedDay = _selectedDay.subtract(const Duration(days: 1));
      } else if (_viewMode == 'week') {
        _selectedDay = _selectedDay.subtract(const Duration(days: 7));
      } else {
        _selectedDay = DateTime(_selectedDay.year, _selectedDay.month - 1);
      }
      _calendarController.displayDate = _selectedDay;
    });
  }

  void _next() {
    setState(() {
      if (_viewMode == 'day') {
        _selectedDay = _selectedDay.add(const Duration(days: 1));
      } else if (_viewMode == 'week') {
        _selectedDay = _selectedDay.add(const Duration(days: 7));
      } else {
        _selectedDay = DateTime(_selectedDay.year, _selectedDay.month + 1);
      }
      _calendarController.displayDate = _selectedDay;
    });
  }

  CalendarView _getCalendarView() {
    switch (_viewMode) {
      case 'day':
        return CalendarView.day;
      case 'month':
        return CalendarView.month;
      case 'week':
      default:
        return CalendarView.week;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final isDark = appProvider.themeMode == ThemeMode.dark;
    final isWeb = MediaQuery.of(context).size.width > 900;
    final provider = context.watch<TaskProvider>();

    final bgColor = isDark ? ghDarkBg : ghLightBg;
    final textColor = isDark ? ghDarkText : ghLightText;
    final borderColor = isDark ? ghDarkBorder : ghLightBorder;

    final filteredTasks = provider.tasks.where((t) {
      final hasProject = t.project_id != null && t.project_id!.isNotEmpty;
      final hasCategory = t.categoryId != null && t.categoryId!.isNotEmpty;

      if (hasProject && hasCategory) {
        return _selectedProjectIds.contains(t.project_id) ||
            _selectedCategoryIds.contains(t.categoryId);
      }
      if (hasProject) {
        return _selectedProjectIds.contains(t.project_id);
      }
      if (hasCategory) {
        return _selectedCategoryIds.contains(t.categoryId);
      }
      return _showUncategorized;
    }).toList();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bgColor,
      drawer: !isWeb ? Drawer(
        backgroundColor: bgColor,
        child: SafeArea(child: _buildLeftPanel(isDark, borderColor, provider, isWeb)),
      ) : null,
      bottomNavigationBar:
          isWeb ? null : const MobileBottomNav(currentRoute: 'calendar'),
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
                      // Panel lọc nội tuyến — chỉ hiển thị trên web khi bật
                      if (isWeb && _showFilterPanel)
                        _buildLeftPanel(isDark, borderColor, provider, isWeb),
                      Expanded(
                        child: _buildMainView(
                          isDark,
                          filteredTasks,
                          borderColor,
                          textColor,
                          provider,
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
    switch (_viewMode) {
      case 'month':
        label = DateFormat('MM/yyyy').format(_selectedDay);
        break;
      case 'day':
        label = DateFormat('dd/MM/yyyy').format(_selectedDay);
        break;
      case 'week':
        final start =
            _selectedDay.subtract(Duration(days: _selectedDay.weekday - 1));
        final end = start.add(const Duration(days: 6));
        label =
            "${DateFormat('dd/MM').format(start)} - ${DateFormat('dd/MM').format(end)}";
        break;
      default:
        label = DateFormat('MM/yyyy').format(_selectedDay);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? ghDarkBg : ghLightBg,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          // Nút toggle panel lọc
          if (isWeb)
            IconButton(
              icon: Icon(
                _showFilterPanel ? Icons.filter_list_off : Icons.filter_list,
                color: _showFilterPanel ? ghBlue : textColor,
                size: 22,
              ),
              tooltip: _showFilterPanel ? "Ẩn bảng lọc" : "Mở bảng lọc",
              onPressed: () => setState(() => _showFilterPanel = !_showFilterPanel),
            )
          else
            IconButton(
              icon: Icon(Icons.menu, color: textColor, size: 24),
              tooltip: "Mở bảng lọc",
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          if (!isWeb)
            IconButton(
              icon: Icon(Icons.arrow_back, color: textColor, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: () => _showViewMenu(isDark),
              child: Row(
                children: [
                  Text(
                    label.toUpperCase(),
                    style: GoogleFonts.nunito(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_drop_down, color: textColor, size: 20),
                ],
              ),
            ),
          ),
          // Chế độ xem nhanh
          _viewChip('N', 'day', isDark),
          _viewChip('T', 'week', isDark),
          _viewChip('M', 'month', isDark),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.chevron_left_rounded, color: textColor, size: 28),
            onPressed: _prev,
          ),
          IconButton(
            icon: Icon(Icons.chevron_right_rounded, color: textColor, size: 28),
            onPressed: _next,
          ),
        ],
      ),
    );
  }

  Widget _viewChip(String label, String mode, bool isDark) {
    final isActive = _viewMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _viewMode = mode;
          _calendarController.view = _getCalendarViewForMode(mode);
          _calendarController.displayDate = _selectedDay;
        });
      },
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive ? ghBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isActive ? null : Border.all(color: ghDarkBorder, width: 1),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.nunito(
              color: isActive ? Colors.white : (isDark ? ghDarkSubText : ghLightText),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  void _showViewMenu(bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? ghDarkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Chế độ hiển thị",
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _vOpt('Xem theo Ngày', 'day', Icons.calendar_today_rounded, ctx),
            const Divider(),
            _vOpt('Xem theo Tuần', 'week', Icons.calendar_view_week_rounded, ctx),
            const Divider(),
            _vOpt('Xem theo Tháng', 'month', Icons.calendar_month_rounded, ctx),
          ],
        ),
      ),
    );
  }

  Widget _vOpt(String l, String v, IconData i, BuildContext ctx) {
    return ListTile(
      leading:
          Icon(i, color: _viewMode == v ? ghBlue : ghDarkSubText, size: 22),
      title: Text(
        l,
        style: GoogleFonts.nunito(
          fontWeight: _viewMode == v ? FontWeight.bold : FontWeight.normal,
          fontSize: 15,
        ),
      ),
      onTap: () {
        setState(() {
          _viewMode = v;
          _calendarController.view = _getCalendarViewForMode(v);
          _calendarController.displayDate = _selectedDay;
        });
        Navigator.pop(ctx);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  CalendarView _getCalendarViewForMode(String mode) {
    switch (mode) {
      case 'day': return CalendarView.day;
      case 'month': return CalendarView.month;
      case 'week': default: return CalendarView.week;
    }
  }

  Widget _buildLeftPanel(
      bool isDark, Color borderColor, TaskProvider provider, bool isWeb) {
    return Container(
      width: isWeb ? 230 : double.infinity,
      decoration: BoxDecoration(
        color: isDark ? ghDarkCard : Colors.white,
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              DateFormat('MMMM yyyy').format(_selectedDay),
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Divider(height: 1, color: borderColor),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              children: [
                _sectionLabel("LỌC THEO DỰ ÁN"),
                ...provider.projects.map(
                  (p) => _filterTile(
                      p.name, _selectedProjectIds.contains(p.project_id), (v) {
                    setState(() {
                      if (v!) {
                        _selectedProjectIds.add(p.project_id);
                      } else {
                        _selectedProjectIds.remove(p.project_id);
                      }
                    });
                  }, color: Color(p.colorValue)),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _sectionLabel("NHÓM CÁ NHÂN"),
                    IconButton(
                      icon: const Icon(Icons.add_box_outlined, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showAddCategoryDialog(isDark, provider),
                    ),
                  ],
                ),
                _filterTile("Chung (Mặc định)", _showUncategorized,
                    (v) => setState(() => _showUncategorized = v!),
                    color: ghBlue),
                ...provider.categories.map(
                  (c) => _filterTileWithActions(
                    c.name,
                    _selectedCategoryIds.contains(c.id),
                    (v) {
                      setState(() {
                        if (v!) {
                          _selectedCategoryIds.add(c.id);
                        } else {
                          _selectedCategoryIds.remove(c.id);
                        }
                      });
                    },
                    color: Color(c.colorValue),
                    onLongPress: () =>
                        _showCategoryOptions(isDark, provider, c),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Palette màu cho nhóm cá nhân (không có đỏ — dành cho dự án)
  static const List<Color> _categoryPalette = [
    Color(0xFF1E88E5), // Xanh dương
    Color(0xFF43A047), // Xanh lá
    Color(0xFFFB8C00), // Cam
    Color(0xFF8E24AA), // Tím
    Color(0xFF00ACC1), // Ngọc lam
    Color(0xFFE91E63), // Hồng
    Color(0xFF6D4C41), // Nâu
    Color(0xFF00BCD4), // Cyan
    Color(0xFFFFB300), // Vàng amber
    Color(0xFF3949AB), // Chàm
    Color(0xFF7CB342), // Lime
    Color(0xFF6200EA), // Tím đậm
    Color(0xFF0097A7), // Xanh biển đậm
    Color(0xFFF4511E), // Cam đỏ (nhạt hơn đỏ)
    Color(0xFF039BE5), // Xanh nhạt
  ];

  void _showAddCategoryDialog(bool isDark, TaskProvider provider,
      {TaskCategory? editCategory}) {
    final isEdit = editCategory != null;
    final controller =
        TextEditingController(text: isEdit ? editCategory.name : '');
    Color selectedColor =
        isEdit ? Color(editCategory.colorValue) : _categoryPalette[0];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? ghDarkCard : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                    color: selectedColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Text(
                isEdit ? "Chỉnh sửa nhóm" : "Tạo nhóm mới",
                style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ],
          ),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Tên nhóm",
                    style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? ghDarkSubText : Colors.black54)),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "Nhập tên nhóm...",
                    hintStyle: GoogleFonts.nunito(
                        color: isDark ? ghDarkSubText : Colors.black38),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF0D1117)
                        : const Color(0xFFF6F8FA),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: isDark ? ghDarkBorder : ghLightBorder)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: isDark ? ghDarkBorder : ghLightBorder)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: ghBlue, width: 2)),
                  ),
                  style: GoogleFonts.nunito(
                      color: isDark ? ghDarkText : Colors.black87),
                ),
                const SizedBox(height: 20),
                Text("Màu sắc (đỏ dành riêng cho Dự án)",
                    style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? ghDarkSubText : Colors.black54)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _categoryPalette
                      .map((color) => GestureDetector(
                            onTap: () =>
                                setDialogState(() => selectedColor = color),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: selectedColor == color ? 36 : 30,
                              height: selectedColor == color ? 36 : 30,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: selectedColor == color
                                    ? Border.all(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                        width: 2.5)
                                    : null,
                                boxShadow: selectedColor == color
                                    ? [
                                        BoxShadow(
                                            color: color.withValues(alpha: 0.5),
                                            blurRadius: 8,
                                            spreadRadius: 1)
                                      ]
                                    : null,
                              ),
                              child: selectedColor == color
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 16)
                                  : null,
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                // Preview
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selectedColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: selectedColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                              color: selectedColor, shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Text(
                        controller.text.isEmpty
                            ? "Tên nhóm của bạn"
                            : controller.text,
                        style: GoogleFonts.nunito(
                            color: selectedColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text("Hủy",
                    style: GoogleFonts.nunito(
                        color: isDark ? ghDarkSubText : Colors.black54))),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) return;
                if (isEdit) {
                  editCategory.name = controller.text.trim();
                  editCategory.colorValue = selectedColor.toARGB32();
                  provider.updateCategory(editCategory);
                } else {
                  provider.addCategory(TaskCategory(
                    id: const Uuid().v4(),
                    name: controller.text.trim(),
                    colorValue: selectedColor.toARGB32(),
                    userId:
                        auth.FirebaseAuth.instance.currentUser?.uid ?? 'guest',
                  ));
                }
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: selectedColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              child: Text(isEdit ? "Lưu" : "Tạo",
                  style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  void _showCategoryOptions(
      bool isDark, TaskProvider provider, TaskCategory category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? ghDarkCard : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: isDark ? ghDarkBorder : ghLightBorder,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                          color: Color(category.colorValue),
                          shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Text(
                    category.name,
                    style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? ghDarkText : Colors.black87),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: ghBlue),
              title: Text("Chỉnh sửa nhóm",
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _showAddCategoryDialog(isDark, provider,
                    editCategory: category);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: Text("Xóa nhóm",
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteCategory(isDark, provider, category);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCategory(
      bool isDark, TaskProvider provider, TaskCategory category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? ghDarkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Xóa nhóm?",
            style:
                GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 17)),
        content: RichText(
          text: TextSpan(
            style: GoogleFonts.nunito(
                color: isDark ? ghDarkText : Colors.black87, fontSize: 14),
            children: [
              const TextSpan(text: "Nhóm "),
              TextSpan(
                  text: '"${category.name}"',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(
                  text:
                      " sẽ bị xóa. Các công việc trong nhóm này sẽ chuyển về nhóm chung."),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Hủy",
                  style: GoogleFonts.nunito(
                      color: isDark ? ghDarkSubText : Colors.black54))),
          ElevatedButton(
            onPressed: () {
              setState(() =>
                  _selectedCategoryIds.remove(category.id));
              provider.deleteCategory(category.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child:
                Text("Xóa", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        text,
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: ghDarkSubText,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _filterTile(String title, bool value, Function(bool?) onChanged,
      {required Color color}) {
    return CheckboxListTile(
      title: Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      visualDensity: VisualDensity.compact,
      activeColor: color,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _filterTileWithActions(
    String title,
    bool value,
    Function(bool?) onChanged, {
    required Color color,
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: CheckboxListTile(
        title: Row(
          children: [
            Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title,
                  style: GoogleFonts.nunito(
                      fontSize: 14, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
            ),
            Icon(Icons.more_horiz,
                size: 16, color: ghDarkSubText.withValues(alpha: 0.6)),
          ],
        ),
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        dense: true,
        visualDensity: VisualDensity.compact,
        activeColor: color,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  List<Appointment> _buildAppointments(
      List<Task> tasks, TaskProvider provider) {
    return tasks.map((task) {
      return Appointment(
        startTime: task.due_day,
        endTime: task.deadline,
        subject: task.title,
        color: provider.getTaskColor(task),
        notes: task.task_id,
      );
    }).toList();
  }

  Widget _buildMainView(
    bool isDark,
    List<Task> tasks,
    Color borderColor,
    Color textColor,
    TaskProvider provider,
  ) {
    return SfCalendar(
      controller: _calendarController,
      view: _getCalendarView(),
      dataSource: TaskCalendarDataSource(_buildAppointments(tasks, provider)),
      initialDisplayDate: _selectedDay,
      todayHighlightColor: ghGreen,
      backgroundColor: isDark ? ghDarkBg : ghLightBg,
      cellBorderColor: borderColor.withValues(alpha: 0.15),
      headerHeight: 0,
      showNavigationArrow: false,
      showDatePickerButton: false,
      viewHeaderHeight: _viewMode == 'month' ? 36 : 56,
      allowDragAndDrop: true,
      allowAppointmentResize: true,
      timeSlotViewSettings: const TimeSlotViewSettings(
        timeIntervalHeight: 64,
        timeFormat: 'HH:mm',
        timeTextStyle: TextStyle(fontSize: 11),
      ),
      monthViewSettings: const MonthViewSettings(
        appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
        showAgenda: false,
      ),
      appointmentBuilder: (context, details) {
        if (details.appointments.isEmpty) return const SizedBox();
        final appointment = details.appointments.first as Appointment;
        final taskId = appointment.notes;
        final task = provider.tasks.firstWhere(
          (t) => t.task_id == taskId,
          orElse: () => tasks.first,
        );

        return TaskHoverCard(
          task: task,
          appointment: appointment,
          provider: provider,
        );
      },
      appointmentTextStyle: GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      onViewChanged: (details) {
        if (details.visibleDates.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedDay = details.visibleDates[
                  details.visibleDates.length ~/ 2
                ];
              });
            }
          });
        }
      },
      onTap: (details) {
        if (details.appointments != null && details.appointments!.isNotEmpty) {
          final appointment = details.appointments!.first as Appointment;
          final taskId = appointment.notes;
          final task = provider.tasks.firstWhere(
            (t) => t.task_id == taskId,
            orElse: () => tasks.first,
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
          );
          return;
        }
        if (details.date != null) {
          showDialog(
            context: context,
            builder: (_) => QuickAddTaskDialog(initialDate: details.date!),
          );
        }
      },
      onDragEnd: (details) async {
        if (details.appointment == null || details.droppingTime == null) return;
        final appointment = details.appointment as Appointment;
        final taskId = appointment.notes;
        final task = provider.tasks.firstWhere(
          (t) => t.task_id == taskId,
          orElse: () => tasks.first,
        );
        
        if (task.project_id != null) {
          final project = provider.projects.where((p) => p.project_id == task.project_id).firstOrNull;
          if (project != null && project.startDate != null && details.droppingTime!.isBefore(project.startDate!)) {
            if (mounted) {
              AppPopup.show(context,
                  title: "Lỗi thời gian",
                  message: "Không thể di chuyển trước ngày bắt đầu dự án (${DateFormat('dd/MM/yyyy HH:mm').format(project.startDate!)})",
                  color: Colors.redAccent);
            }
            setState(() {});
            return;
          }
        }

        final duration = task.duration;
        task.due_day = details.droppingTime!;
        task.deadline = details.droppingTime!.add(Duration(minutes: duration));
        task.updatedAt = DateTime.now();
        task.isSynced = false;
        await provider.updateTask(task);
        if (mounted) {
          AppPopup.show(context,
              title: "Đã cập nhật",
              message: "Đã di chuyển '${task.title}'",
              color: ghBlue);
        }
      },
      onAppointmentResizeEnd: (details) async {
        if (details.appointment == null ||
            details.startTime == null ||
            details.endTime == null) {
          return;
        }
        final appointment = details.appointment as Appointment;
        final taskId = appointment.notes;
        final task = provider.tasks.firstWhere(
          (t) => t.task_id == taskId,
          orElse: () => tasks.first,
        );
        
        if (task.project_id != null) {
          final project = provider.projects.where((p) => p.project_id == task.project_id).firstOrNull;
          if (project != null && project.startDate != null && details.startTime!.isBefore(project.startDate!)) {
            if (mounted) {
              AppPopup.show(context,
                  title: "Lỗi thời gian",
                  message: "Thời gian bắt đầu không được trước ngày bắt đầu dự án (${DateFormat('dd/MM/yyyy HH:mm').format(project.startDate!)})",
                  color: Colors.redAccent);
            }
            setState(() {});
            return;
          }
        }

        task.due_day = details.startTime!;
        task.deadline = details.endTime!;
        task.duration =
            details.endTime!.difference(details.startTime!).inMinutes;
        task.updatedAt = DateTime.now();
        task.isSynced = false;
        await provider.updateTask(task);
        if (mounted) {
          AppPopup.show(context,
              title: "Đã cập nhật",
              message: "Đã thay đổi thời lượng",
              color: ghGreen);
        }
      },
    );
  }
}

class TaskCalendarDataSource extends CalendarDataSource {
  TaskCalendarDataSource(List<Appointment> source) {
    appointments = source;
  }
}

class TaskHoverCard extends StatefulWidget {
  final Task task;
  final Appointment appointment;
  final TaskProvider provider;

  const TaskHoverCard({
    super.key,
    required this.task,
    required this.appointment,
    required this.provider,
  });

  @override
  State<TaskHoverCard> createState() => _TaskHoverCardState();
}

class _TaskHoverCardState extends State<TaskHoverCard> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isHovered = false;

  void _showOverlay(BuildContext context) {
    if (_overlayEntry != null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: 340,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.topRight,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(8, 0),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: isDark ? const Color(0xFF161B22) : Colors.white,
              child: MouseRegion(
                onEnter: (_) {
                  _isHovered = true;
                },
                onExit: (_) {
                  _isHovered = false;
                  _hideOverlay();
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: widget.appointment.color, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.task.title,
                              style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? const Color(0xFFC9D1D9) : const Color(0xFF24292F)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${DateFormat('HH:mm').format(widget.task.due_day)} - ${DateFormat('HH:mm').format(widget.task.deadline)}",
                        style: GoogleFonts.nunito(fontSize: 13, color: isDark ? const Color(0xFF8B949E) : const Color(0xFF57606A)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.copy, size: 16, color: Color(0xFF58A6FF)),
                            label: Text("Nhân bản", style: GoogleFonts.nunito(color: const Color(0xFF58A6FF), fontSize: 13)),
                            onPressed: () {
                              _hideOverlay();
                              final newTask = Task(
                                task_id: const Uuid().v4(),
                                user_id: widget.task.user_id,
                                title: "${widget.task.title} (Bản sao)",
                                description: widget.task.description,
                                due_day: widget.task.due_day,
                                priority: widget.task.priority,
                                progress: widget.task.progress,
                                duration: widget.task.duration,
                                deadline: widget.task.deadline,
                                status: widget.task.status,
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                                isSynced: false,
                                isDeleted: false,
                                category: widget.task.category,
                                orderIndex: widget.task.orderIndex,
                                project_id: widget.task.project_id,
                                assigneeId: widget.task.assigneeId,
                                attachments: List.from(widget.task.attachments),
                                reminder: widget.task.reminder,
                                categoryId: widget.task.categoryId,
                              );
                              widget.provider.addTask(newTask);
                              AppPopup.success(context, "Đã nhân bản công việc!");
                            },
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.edit, size: 16, color: Color(0xFF3FB950)),
                            label: Text("Sửa", style: GoogleFonts.nunito(color: const Color(0xFF3FB950), fontSize: 13)),
                            onPressed: () {
                              _hideOverlay();
                              showDialog(
                                context: context,
                                builder: (_) => QuickEditTaskDialog(task: widget.task),
                              );
                            },
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                            label: Text("Xóa", style: GoogleFonts.nunito(color: Colors.redAccent, fontSize: 13)),
                            onPressed: () {
                              _hideOverlay();
                              widget.provider.deleteTask(widget.task.task_id);
                              AppPopup.show(context, title: "Đã xóa", message: "Công việc đã được chuyển vào thùng rác", color: Colors.redAccent);
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_isHovered && mounted) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      }
    });
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) {
          _isHovered = true;
          _showOverlay(context);
        },
        onExit: (_) {
          _isHovered = false;
          _hideOverlay();
        },
        child: Container(
          decoration: BoxDecoration(
            color: widget.appointment.color,
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            widget.appointment.subject,
            style: GoogleFonts.nunito(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
