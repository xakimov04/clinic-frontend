import 'package:clinic/core/constants/color_constants.dart';
import 'package:clinic/features/client/home/presentation/bloc/clinics/clinics_bloc.dart';
import 'package:clinic/features/client/home/presentation/bloc/doctor/doctor_bloc.dart';
import 'package:clinic/features/client/home/presentation/bloc/illness/illness_bloc.dart';
import 'package:clinic/features/client/home/presentation/widgets/category_card.dart';
import 'package:clinic/features/client/home/presentation/widgets/clinics_item.dart';
import 'package:clinic/features/client/home/presentation/widgets/doctor_items.dart';
import 'package:clinic/features/client/home/presentation/widgets/illness_categories.dart';
import 'package:clinic/features/client/notification/notification_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  // Telefon uchun: 0=Врачи, 1=Клиники
  // Planshet uchun: 0=Врачи, 1=Клиники, 2=Категории
  int _currentIndex = 0;

  bool _doctorsLoaded = false;
  bool _clinicsLoaded = false;

  bool get _isTablet => MediaQuery.of(context).size.width > 600;

  @override
  void initState() {
    super.initState();
    context.read<IllnessBloc>().add(IllnessGetAll());
    _loadDoctorsData();
  }

  void _loadDoctorsData() {
    if (!_doctorsLoaded) {
      context.read<DoctorBloc>().add(const GetDoctorEvent());
      _doctorsLoaded = true;
    }
  }

  void _loadClinicsData() {
    if (!_clinicsLoaded) {
      context.read<ClinicsBloc>().add(const GetClinicsEvent());
      _clinicsLoaded = true;
    }
  }

  void _switchTab(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });

      if (_isTablet) {
        // Planshet: 0=Врачи, 1=Клиники, 2=Категории
        if (index == 0) _loadDoctorsData();
        if (index == 1) _loadClinicsData();
      } else {
        // Telefon: 0=Врачи, 1=Клиники
        if (index == 0) _loadDoctorsData();
        if (index == 1) _loadClinicsData();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'МедЦентр',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: ColorConstants.primaryColor,
              ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: ColorConstants.shadowColor.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: ColorConstants.primaryColor,
              ),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationPage(),
                    ));
              },
            ),
          ),
        ],
      ),
      body: RefreshIndicator.adaptive(
        backgroundColor: ColorConstants.backgroundColor,
        color: ColorConstants.primaryColor,
        onRefresh: () async {
          if (_isTablet) {
            if (_currentIndex == 0) {
              context.read<DoctorBloc>().add(const GetDoctorEvent());
            } else if (_currentIndex == 1) {
              context.read<ClinicsBloc>().add(const GetClinicsEvent());
            } else if (_currentIndex == 2) {
              context.read<IllnessBloc>().add(IllnessGetAllNotLoading());
            }
          } else {
            if (_currentIndex == 0) {
              context.read<DoctorBloc>().add(const GetDoctorEvent());
              context.read<IllnessBloc>().add(IllnessGetAllNotLoading());
            } else if (_currentIndex == 1) {
              context.read<ClinicsBloc>().add(const GetClinicsEvent());
              context.read<IllnessBloc>().add(IllnessGetAllNotLoading());
            }
          }
        },
        child: _isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
      ),
    );
  }

  // ==================== TELEFON LAYOUT ====================
  Widget _buildPhoneLayout() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(child: IllnessCategories()),
        SliverToBoxAdapter(child: _buildPhoneTabBar()),
        SliverToBoxAdapter(
          child:
              _currentIndex == 0 ? const DoctorItems() : const ClinicsItem(),
        ),
      ],
    );
  }

  // ==================== PLANSHET LAYOUT ====================
  Widget _buildTabletLayout() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // 3 tab: Категории | Врачи | Клиники
        SliverToBoxAdapter(child: _buildTabletTabBar()),

        // Tanlangan tabga mos content
        SliverToBoxAdapter(child: _buildTabletContent()),
      ],
    );
  }

  Widget _buildTabletContent() {
    switch (_currentIndex) {
      case 0:
        return const DoctorItems(isTablet: true);
      case 1:
        return const ClinicsItem(isTablet: true);
      case 2:
        return _buildTabletCategories();
      default:
        return const SizedBox.shrink();
    }
  }

  // Planshet uchun kategoriyalar wrap ko'rinishda
  Widget _buildTabletCategories() {
    return BlocBuilder<IllnessBloc, IllnessState>(
      builder: (context, state) {
        if (state is IllnessLoading || state is IllnessInitial) {
          return _buildTabletCategoriesLoading();
        }
        // Agar detail sahifasidan qaytgan bo'lsa, qayta yuklash
        if (state is! IllnessLoaded) {
          context.read<IllnessBloc>().add(IllnessGetAllNotLoading());
          return _buildTabletCategoriesLoading();
        }
        if (state is IllnessLoaded) {
          final screenWidth = MediaQuery.of(context).size.width;
          final crossAxisCount = screenWidth > 900 ? 5 : 4;
          final spacing = 12.0;
          final itemWidth =
              (screenWidth - 32 - (crossAxisCount - 1) * spacing) /
                  crossAxisCount;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final illness in state.illnesses)
                  SizedBox(
                    width: itemWidth,
                    child: CategoryCard(illness: illness),
                  ),
              ],
            ),
          );
        }
        if (state is IllnessError || state is IllnessEmpty) {
          return const SizedBox.shrink();
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTabletCategoriesLoading() {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 900 ? 5 : 4;
    final spacing = 12.0;
    final itemWidth =
        (screenWidth - 32 - (crossAxisCount - 1) * spacing) / crossAxisCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: List.generate(
          8,
          (i) => Container(
            width: itemWidth,
            height: itemWidth / 0.9,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== TELEFON TAB BAR (2 tab) ====================
  Widget _buildPhoneTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.shadowColor.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutQuint,
                left: _currentIndex * totalWidth / 2,
                top: 0,
                bottom: 0,
                width: totalWidth / 2,
                child: _buildActiveTabBackground(),
              ),
              Row(
                children: [
                  _buildTabButton(
                      "Врачи", 0, Icons.medical_services_outlined),
                  _buildTabButton(
                      "Клиники", 1, Icons.local_hospital_outlined),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ==================== PLANSHET TAB BAR (3 tab) ====================
  Widget _buildTabletTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.shadowColor.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final tabWidth = totalWidth / 3;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutQuint,
                left: _currentIndex * tabWidth,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: _buildActiveTabBackground(),
              ),
              Row(
                children: [
                  _buildTabButton(
                      "Врачи", 0, Icons.medical_services_outlined),
                  _buildTabButton(
                      "Клиники", 1, Icons.local_hospital_outlined),
                  _buildTabButton(
                      "Категории", 2, Icons.category_outlined),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActiveTabBackground() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: ColorConstants.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: ColorConstants.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index, IconData icon) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _switchTab(index),
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.transparent,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? Colors.white
                      : ColorConstants.secondaryTextColor,
                  size: isSelected ? 22 : 18,
                ),
                const SizedBox(width: 8),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: isSelected ? 16 : 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : ColorConstants.secondaryTextColor,
                  ),
                  child: Text(text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
