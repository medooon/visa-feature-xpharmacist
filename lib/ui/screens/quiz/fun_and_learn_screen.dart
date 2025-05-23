import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutterquiz/app/routes.dart';
import 'package:flutterquiz/features/quiz/models/comprehension.dart';
import 'package:flutterquiz/features/quiz/models/quiz_type.dart';
import 'package:flutterquiz/ui/widgets/custom_appbar.dart';
import 'package:flutterquiz/utils/constants/fonts.dart';
import 'package:flutterquiz/utils/constants/string_labels.dart';
import 'package:flutterquiz/utils/extensions.dart';
import 'package:flutterquiz/utils/ui_utils.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:screen_protector/screen_protector.dart';

class FunAndLearnScreen extends StatefulWidget {
  const FunAndLearnScreen({
    required this.quizType,
    required this.comprehension,
    super.key,
  });

  final QuizTypes quizType;
  final Comprehension comprehension;

  @override
  State<FunAndLearnScreen> createState() => _FunAndLearnScreen();

  static Route<dynamic> route(RouteSettings routeSettings) {
    final arguments = routeSettings.arguments as Map?;
    return CupertinoPageRoute(
      builder: (_) => FunAndLearnScreen(
        quizType: arguments!['quizType'] as QuizTypes,
        comprehension: arguments['comprehension'] as Comprehension,
      ),
    );
  }
}

class _FunAndLearnScreen extends State<FunAndLearnScreen>
    with TickerProviderStateMixin {
  late final _ytController = YoutubePlayerController(
    initialVideoId: widget.comprehension.contentData,
    flags: const YoutubePlayerFlags(
      autoPlay: false,
    ),
  );

  @override
  void initState() {
    super.initState();
    _enableScreenProtection();
  }

  Future<void> _enableScreenProtection() async {
    try {
      await ScreenProtector.preventScreenshotOn();
    } catch (e) {
      debugPrint("Error enabling screen protection: $e");
    }
  }

  Future<void> _disableScreenProtection() async {
    try {
      await ScreenProtector.preventScreenshotOff();
    } catch (e) {
      debugPrint("Error disabling screen protection: $e");
    }
  }

  @override
  void dispose() {
    _ytController.dispose();
    _disableScreenProtection();
    super.dispose();
  }

  bool showFullPdf = false;

  Widget _buildParagraph(Widget player) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      // أزلنا أي ارتفاع ثابت حتى يشبه الإصدار القديم
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(10), // حواف ثابتة 16 بكسل من جميع الجهات
        child: Column(
          children: [
            // محتوى الفيديو
            if (widget.comprehension.contentType == ContentType.yt) player,

            // محتوى الـ PDF
            if (widget.comprehension.contentType == ContentType.pdf) ...[
              // أزلنا الـ height عن الـ SizedBox حتى يتمدد بحسب المحتوى
              // أو يمكنك استبداله بـ Container دون تحديد ارتفاع
              Container(
                constraints: BoxConstraints(
                  // حد أقصى للارتفاع لمنع تمدد PDF بلا حدود 
                  maxHeight: MediaQuery.of(context).size.height * (showFullPdf ? 0.7 : 0.2),
                ),
                child: const PDF(
                  swipeHorizontal: true,
                  fitPolicy: FitPolicy.BOTH,
                ).fromUrl(widget.comprehension.contentData),
              ),
              TextButton(
                onPressed: () => setState(() => showFullPdf = !showFullPdf),
                child: Text(
                  showFullPdf ? 'Show Less' : 'Show Full',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onTertiary,
                        decoration: TextDecoration.underline,
                      ),
                ),
              ),
            ],

            // محتوى النص (HTML)
            const SizedBox(height: 10),
            HtmlWidget(
              widget.comprehension.detail,
              onErrorBuilder: (_, e, err) => Text('$e error: $err'),
              onLoadingBuilder: (_, __, ___) => const Center(
                child: CircularProgressIndicator(),
              ),
              textStyle: TextStyle(
                color: Theme.of(context).colorScheme.onTertiary,
                fontWeight: FontWeights.regular,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _ytController,
        progressIndicatorColor: Theme.of(context).primaryColor,
        progressColors: ProgressBarColors(
          playedColor: Theme.of(context).primaryColor,
          bufferedColor:
              Theme.of(context).colorScheme.onTertiary.withOpacity(0.5),
          backgroundColor:
              Theme.of(context).colorScheme.surface.withOpacity(0.5),
          handleColor: Theme.of(context).primaryColor,
        ),
      ),
      onExitFullScreen: () {
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );
      },
      builder: (context, player) {
        return Scaffold(
          appBar: QAppBar(
            roundedAppBar: false,
            title: Text(widget.comprehension.title),
          ),
          body: Center(
            child: _buildParagraph(player),
          ),
        );
      },
    );
  }
}
