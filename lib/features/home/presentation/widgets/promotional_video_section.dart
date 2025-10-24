import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../../core/services/app_context_service.dart';
import '../../../../core/theme/app_theme.dart';

class PromotionalVideoSection extends StatefulWidget {
  const PromotionalVideoSection({super.key});

  @override
  State<PromotionalVideoSection> createState() =>
      _PromotionalVideoSectionState();
}

class _PromotionalVideoSectionState extends State<PromotionalVideoSection> {
  late YoutubePlayerController _youtubeController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeYoutubePlayer();
  }

  void _initializeYoutubePlayer() {
    _youtubeController = YoutubePlayerController.fromVideoId(
      videoId: AppContextService.promoYoutubeVideoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: false, // THIS REMOVES ALL YOUTUBE CONTROLS
        mute: false,
        showFullscreenButton: false,
        loop: false,
        strictRelatedVideos: true,
        enableCaption: false,
        showVideoAnnotations: false,
        playsInline: true,
      ),
    );

    // Listen to player state changes
    _youtubeController.listen((event) {
      if (event.playerState == PlayerState.playing) {
        if (!_isPlaying) {
          setState(() => _isPlaying = true);
        }
      } else if (event.playerState == PlayerState.paused ||
          event.playerState == PlayerState.ended) {
        if (_isPlaying) {
          setState(() => _isPlaying = false);
        }
      }
    });

    print(
      '📺 YouTube Player (iframe) initialized with video: ${AppContextService.promoYoutubeUrl}',
    );
  }

  @override
  void dispose() {
    _youtubeController.close();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_isPlaying) {
        _youtubeController.pauseVideo();
        _isPlaying = false;
        print('⏸️ Video paused');
      } else {
        _youtubeController.playVideo();
        _isPlaying = true;
        print('▶️ Video playing');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Watch Our Story',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // YouTube Player
                    Positioned.fill(
                      child: YoutubePlayer(
                        controller: _youtubeController,
                        aspectRatio: 16 / 9,
                      ),
                    ),

                    // COMPREHENSIVE OVERLAY TO COMPLETELY BLOCK ALL YOUTUBE CONTROLS
                    // Cover ENTIRE bottom area where controls appear
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _togglePlayPause,
                        child: Container(
                          height: 80, // Cover entire control bar area
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Cover top area (YouTube logo)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _togglePlayPause,
                        child: Container(height: 60, color: Colors.transparent),
                      ),
                    ),

                    // Custom Play/Pause Button
                    Center(
                      child: GestureDetector(
                        onTap: _togglePlayPause,
                        child: AnimatedOpacity(
                          opacity: _isPlaying ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.8),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Show pause button on tap when playing
                    if (_isPlaying)
                      Center(
                        child: GestureDetector(
                          onTap: _togglePlayPause,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 1.0, end: 0.0),
                            duration: const Duration(seconds: 2),
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.8),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.pause,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
