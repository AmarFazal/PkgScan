import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../constants/app_colors.dart';
import '../constants/text_constants.dart';
import '../constants/ui_helper.dart';
import '../models/video.dart';

class TutorialsScreen extends StatefulWidget {
  const TutorialsScreen({super.key});

  @override
  State<TutorialsScreen> createState() => _TutorialsScreenState();
}

class _TutorialsScreenState extends State<TutorialsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          TextConstants.tutorials,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      backgroundColor: AppColors.primaryColor,
      body: Container(
        margin: const EdgeInsets.only(top: 5),
        decoration: const BoxDecoration(
          color: AppColors.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          child: ListView.builder(
            cacheExtent: 5000,
            padding: const EdgeInsets.all(16.0),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              return VideoCard(
                videoUrl: videos[index].url,
                title: videos[index].title,
                description: videos[index].description,
              );
            },
          ),
        ),
      ),
    );
  }
}

class VideoCard extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String description;

  const VideoCard({
    super.key,
    required this.videoUrl,
    required this.description,
    required this.title,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  late VideoPlayerController _controller;
  bool _isMuted = false;
  bool disposeController = false;

  String _videoDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return [
      if (duration.inHours > 0) hours,
      minutes,
      seconds,
    ].join(":");
  }

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    if (!disposeController) {
      _controller.dispose();
      print("Sayfa butona basılmadan terk edildi, dispose çalıştı!");
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondaryColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
                VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: AppColors.primaryColor,
                    bufferedColor: Colors.white30,
                    backgroundColor: Colors.grey,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 15,
                      color: AppColors.primaryColor,
                      constraints:
                          const BoxConstraints(minWidth: 30, minHeight: 30),
                      icon: Icon(_controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow),
                      onPressed: () {
                        setState(() {
                          _controller.value.isPlaying
                              ? _controller.pause()
                              : _controller.play();
                        });
                      },
                    ),
                    ValueListenableBuilder(
                      valueListenable: _controller,
                      builder: (context, VideoPlayerValue value, child) {
                        return Text(
                          "${_videoDuration(value.position)} / ${_videoDuration(_controller.value.duration)}",
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: AppColors.primaryColor),
                        );
                      },
                    ),
                    const Spacer(),
                    IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 15,
                      color: AppColors.primaryColor,
                      constraints:
                          const BoxConstraints(minWidth: 30, minHeight: 30),
                      icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up),
                      onPressed: () {
                        setState(() {
                          _isMuted = !_isMuted;
                          _controller.setVolume(_isMuted ? 0 : 1);
                        });
                      },
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      color: AppColors.primaryColor,
                      constraints:
                          const BoxConstraints(minWidth: 30, minHeight: 30),
                      icon: const Icon(Icons.fullscreen_rounded),
                      onPressed: () async{
                        disposeController = true;
                        bool? result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                FullScreenVideo(player: _controller),
                          ),
                        );
                        disposeController = false;
                        if (result == false) {
                          print("Butonla gidildi, geri dönüldü ve false alındı.");
                        }
                        // Fullscreen işlemi burada yapılabilir
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          UIHelper.smallVerticalGap,
          Text(
            widget.title,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          UIHelper.extraSmallVerticalGap,
          Text(
            widget.description,
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ],
      ),
    );
  }
}

class FullScreenVideo extends StatefulWidget {
  final VideoPlayerController player;

  const FullScreenVideo({super.key, required this.player});

  @override
  State<FullScreenVideo> createState() => _FullScreenVideoState();
}

class _FullScreenVideoState extends State<FullScreenVideo> {
  bool _isControlsVisible = true;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }


  String _videoDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return [
      if (duration.inHours > 0) hours,
      minutes,
      seconds,
    ].join(":");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          setState(() {
            _isControlsVisible = !_isControlsVisible;
          });
        },
        onDoubleTap: () {
          setState(() {
            if (widget.player.value.isPlaying) {
              widget.player.pause();
            } else {
              widget.player.play();
            }
          });
        },
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: widget.player.value.aspectRatio,
                child: VideoPlayer(widget.player),
              ),
            ),

            // Kontroller
            if (_isControlsVisible)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  children: [
                    // İlerleme çubuğu
                    VideoProgressIndicator(
                      widget.player,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: AppColors.primaryColor,
                        bufferedColor: Colors.white30,
                        backgroundColor: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Oynat / Durdur
                        _buildControlButton(
                          icon: widget.player.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          onTap: () {
                            setState(() {
                              widget.player.value.isPlaying
                                  ? widget.player.pause()
                                  : widget.player.play();
                            });
                          },
                        ),

                        UIHelper.smallHorizontalGap,
                        // Süre göstergesi
                        ValueListenableBuilder(
                          valueListenable: widget.player,
                          builder: (context, VideoPlayerValue value, child) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black38,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                "${_videoDuration(value.position)} / ${_videoDuration(widget.player.value.duration)}",
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                              ),
                            );
                          },
                        ),

                        Spacer(),
                        // Ses Aç/Kapa
                        _buildControlButton(
                          icon: _isMuted ? Icons.volume_off : Icons.volume_up,
                          onTap: () {
                            setState(() {
                              _isMuted = !_isMuted;
                              widget.player.setVolume(_isMuted ? 0 : 1);
                            });
                          },
                        ),
                        UIHelper.smallHorizontalGap,
                        _buildControlButton(
                          icon: Icons.fullscreen_exit,
                          onTap: () => Navigator.pop(context, false),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(
      {required IconData icon, required VoidCallback onTap}) {
    return Container(
      height: 32,
      width: 32,
      decoration: const BoxDecoration(
        color: Colors.black38, // Şeffaf arka plan
        shape: BoxShape.circle,
      ),
      child: IconButton(
        iconSize: 15,
        color: Colors.white,
        icon: Icon(icon),
        onPressed: onTap,
      ),
    );
  }
}
