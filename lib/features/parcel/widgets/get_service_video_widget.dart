import 'package:flutter/material.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:video_player/video_player.dart';

class GetServiceVideoWidget extends StatefulWidget {
  final String youtubeVideoUrl;
  final String fileVideoUrl;
  const GetServiceVideoWidget({super.key, required this.youtubeVideoUrl, required this.fileVideoUrl});

  @override
  State<GetServiceVideoWidget> createState() => _GetServiceVideoWidgetState();
}

class _GetServiceVideoWidgetState extends State<GetServiceVideoWidget> {

  VideoPlayerController? _videoPlayerController;
  YoutubePlayerController? _youtubeController;
  bool _isYoutubeVideo = false;

  @override
  void initState() {
    super.initState();

    String mediaUrl = widget.youtubeVideoUrl;
    final String? videoId = YoutubePlayer.convertUrlToId(mediaUrl);
    if(videoId != null && videoId.isNotEmpty) {
      _isYoutubeVideo = true;
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: true,
        ),
      );
    } else if(widget.fileVideoUrl.isNotEmpty){
      _isYoutubeVideo = false;
      configureForMp4(widget.fileVideoUrl);
    }
  }

  void configureForMp4(String videoUrl) {
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
        }
      });
    _videoPlayerController?.play();
    _videoPlayerController?.setVolume(0);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _videoPlayerController != null) {
        _videoPlayerController?.pause();
        _videoPlayerController?.setVolume(1);
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isYoutubeVideo && _youtubeController != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        child: YoutubePlayer(
          controller: _youtubeController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Colors.amber,
          progressColors: const ProgressBarColors(
            playedColor: Colors.amber,
            handleColor: Colors.amberAccent,
          ),
        ),
      );
    } else if (!_isYoutubeVideo && _videoPlayerController != null) {
      return Stack(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          child: _videoPlayerController!.value.isInitialized ? AspectRatio(
            aspectRatio: _videoPlayerController!.value.aspectRatio,
            child: VideoPlayer(_videoPlayerController!),
          ) : const SizedBox(),
        ),

        _videoPlayerController!.value.isInitialized ? Positioned(bottom: 10, left: 20,
          child: InkWell(
            onTap: (){
              if (mounted) {
                setState(() {
                  _videoPlayerController!.value.isPlaying ? _videoPlayerController!.pause() : _videoPlayerController!.play();
                });
              }
            },
            child: Icon(_videoPlayerController!.value.isPlaying ? Icons.pause : Icons.play_arrow, size: 34),
          ),
        ) : const SizedBox(),
      ]);
    }
    return const SizedBox();
  }
}