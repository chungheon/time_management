import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:time_management/controllers/document_viewer_controller.dart';
import 'package:time_management/controllers/goals_controller.dart';
import 'package:time_management/controllers/routine_controller.dart';
import 'package:time_management/controllers/view_controller.dart';
import 'package:time_management/screens/goals_page.dart';
import 'package:time_management/screens/overview_page..dart';
import 'package:time_management/screens/task_list_page.dart';
import 'package:time_management/styles.dart';
import 'package:time_management/widgets/date_header_widget.dart';
import 'package:time_management/widgets/document_list.dart';
import 'package:time_management/widgets/loading_page_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  TabController? _tabController;
  final ViewController _viewController = Get.find<ViewController>();
  final DocumentViewerController _documentViewerController =
      Get.find<DocumentViewerController>();
  final Rxn<dynamic> args = Rxn<dynamic>();

  AppLifecycleListener? _appLifecycleListener;
  void updateDate() {
    bool hasChanged = _viewController.updateDate();
    if (hasChanged) {
      Get.offUntil(
          GetPageRoute(
              page: () => LoadingPageWidget(asyncFunc: () async {
                    GoalsController goalsController =
                        Get.find<GoalsController>();
                    RoutineController routineController =
                        Get.find<RoutineController>();
                    await goalsController.refreshList();
                    await routineController.refreshList();
                    return;
                  }, onComplete: (_) {
                    Get.until((route) => route.isFirst);
                  })),
          (route) => route.isFirst);
    }
  }

  @override
  void initState() {
    super.initState();
    _appLifecycleListener = AppLifecycleListener(onResume: () {
      updateDate();
    });
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (_tabController!.indexIsChanging) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    args.value = ModalRoute.of(context)!.settings.arguments;

    if (args.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_tabController != null &&
            (_tabController!.length - 1) >=
                (int.tryParse(args.value['page']) ?? _tabController!.length)) {
          _tabController!.animateTo(
              int.tryParse(args.value['page']) ?? _tabController!.length);
        }
      });
    }

    return Scaffold(
      appBar: DateHeaderWidget(
        update: updateDate,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SizedBox(
              height: 30.0,
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.black,
                dividerHeight: 0.0,
                tabs: [
                  Tab(
                    child: Container(
                      margin: const EdgeInsets.only(right: 5.0),
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Text(
                        "Tasks",
                        style: AppStyles.tabTitle(context),
                      ),
                    ),
                  ),
                  Tab(
                    child: Container(
                      margin: const EdgeInsets.only(right: 5.0),
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Text(
                        "Goals",
                        style: AppStyles.tabTitle(context),
                      ),
                    ),
                  ),
                  Tab(
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Text(
                        "Overview",
                        style: AppStyles.tabTitle(context),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                TaskListPage(),
                const GoalsPage(),
                OverviewPage(),
              ],
            ),
          ),
          Obx(
            () {
              double maxHeight = 0.0;
              if (_documentViewerController.openedDocs.isNotEmpty) {
                maxHeight = 20.0;
              }
              if (!_documentViewerController.homePageView.value) {
                maxHeight = 150.0;
              }

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          _documentViewerController.homePageView.value =
                              !_documentViewerController.homePageView.value;
                        },
                        child: Container(
                          height: 20,
                          width: 50,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(7.0)),
                          ),
                        ),
                      ),
                    ),
                    const DocumentList(),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
