library video_playback;

import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';
import 'debug.dart';


class VideoPlayback extends StatefulWidget {

  final ValueNotifier<String> videoLocationNotifier;
  final String videoLocation;
  bool controlsVisible;
  bool autoPlayback;

  _VideoPlaybackState createState() => _VideoPlaybackState();

  VideoPlayback({ this.videoLocationNotifier, this.videoLocation, this.controlsVisible = true, autoPlayback = false});
}

class _VideoPlaybackState extends State<VideoPlayback> {
  VideoPlayerController _controller;
  Duration videoLength;
  Duration videoPosition;
  double volume = 0.5;
  Future<void> _initializeVideoPlayerFuture;
  bool aboutToSetState = false;
  String location;


  @override
  void initState() {
    super.initState();

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   //if (widget.autoPlayback)
    //   _controller.play();
    // });
  }


  Future<void>  updatePlayerWithLocation(location) async {
    debugMessage('New Location $location');
    if(_controller!=null)
      _controller.dispose();
    _controller = VideoPlayerController.network(location);
    _controller.addListener(() {
      aboutToSetState = true;
      setState(() {
        videoPosition = _controller.value.position;
      });
      //when the player get to the end of the video
      if(_controller.value.position == _controller.value.duration) {
        _controller.seekTo(Duration(seconds: 0, minutes: 0, hours: 0));
        debugMessage("End of Video");
        _controller.pause();
        setState(() {
        });
      }
    });
    debugMessage('PLAYER - About to initialise controller');
    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      debugMessage('PLAYER - Is controller initialised? - ${_controller.value.initialized}');
      aboutToSetState = true;
      // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
      setState(() {
        videoLength = _controller.value.duration;
      });
    });
    return _initializeVideoPlayerFuture;
  }



  @override
  Widget build(BuildContext context) {

    //if location is passed when creating widget, ignore notifier
    if(!aboutToSetState) {
      if (isSuitableValue(widget.videoLocation))  {
        debugMessage('location available on instantiation ${widget.videoLocation}');
        _initializeVideoPlayerFuture = updatePlayerWithLocation(widget.videoLocation);
        FutureBuilder(
          future: _initializeVideoPlayerFuture,
          builder: (context, snapshot) {
            return getVideoWidget();
          },
        );
      }
      else {
        return buildLocationListener();
      }
    }
    aboutToSetState = false;
    return getVideoWidget();

  }

  Widget buildLocationListener() {
    if(widget.videoLocationNotifier == null) {
      debugMessage('VIDEO_PLAYBACK: Location Notifier is null');
      return Text('Error displaying Video Playback..');
    }
    return ValueListenableBuilder(
      valueListenable: widget.videoLocationNotifier,
      builder: (BuildContext context, String loc, Widget child) {
        debugMessage("BUILDING PLAYER WITH LOCATION - $loc");
        if (loc == '' || loc == null) {
          debugMessage('show circular indicator');
          return Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 5,),
              Text('Awaiting Video Notification'),
            ],
          );
        }
        else {
          _initializeVideoPlayerFuture = updatePlayerWithLocation(loc);
          return FutureBuilder(
            future: _initializeVideoPlayerFuture,
            builder: (context, snapshot) {
              return getVideoWidget();
            },
          );
        }
      },
      child: Container(),
    );
  }


  Widget getVideoWidget()  {
    return Column(
      children: <Widget>[
        Container(
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: <Widget>[
                VideoPlayer(_controller),
                (widget.controlsVisible) ? _ControlsOverlay(controller: _controller) : Container(),
              ],
            ),
          ),
        ),
        Container(
          child: (widget.controlsVisible) ? VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            padding: EdgeInsets.only(top:5),
          ) : Container(),
        ),
      ],
    );



    //   Column(key: Key('123'),
    //   children: [
    //     if (_controller.value.initialized) ...[
    //       AspectRatio(
    //         aspectRatio: _controller.value.aspectRatio,
    //         child: VideoPlayer(_controller),
    //       ),
    //       VideoProgressIndicator(
    //         _controller,
    //         allowScrubbing: true,
    //         padding: EdgeInsets.all(10),
    //       ),
    //       _ControlsOverlay(controller: _controller),
    //       // Row(
    //       //   children: <Widget>[
    //       //     IconButton(
    //       //       icon: Icon(
    //       //         _controller.value.isPlaying
    //       //             ? Icons.pause
    //       //             : Icons.play_arrow,
    //       //       ),
    //       //       onPressed: () {
    //       //         aboutToSetState = true;
    //       //         setState( () {
    //       //           _controller.value.isPlaying
    //       //               ? _controller.pause()
    //       //               : _controller.play();
    //       //         }
    //       //         );
    //       //       }
    //       //     ),
    //       //     Text(
    //       //         '${convertToMinutesSeconds(videoPosition)} / ${convertToMinutesSeconds(videoLength)}'),
    //       //     SizedBox(width: 10),
    //       //     Icon(animatedVolumeIcon(volume)),
    //       //     Slider(
    //       //         value: volume,
    //       //         min: 0,
    //       //         max: 1,
    //       //         onChanged: (changedVolume) {
    //       //           setState(() {
    //       //             aboutToSetState = true;
    //       //             volume = changedVolume;
    //       //             _controller.setVolume(changedVolume);
    //       //           });
    //       //         }),
    //       //     Spacer(),
    //       //     IconButton(
    //       //         icon: Icon(Icons.loop,
    //       //             color: _controller.value.isLooping
    //       //                 ? Colors.green
    //       //                 : Colors.black),
    //       //         onPressed: () {
    //       //           _controller.setLooping(!_controller.value.isLooping);
    //       //         })
    //       //   ],
    //       // )
    //     ]
    //   ],
    // );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}

String convertToMinutesSeconds(Duration duration) {
  final parsedMinutes = duration.inMinutes % 60;

  final minutes =
  parsedMinutes < 10 ? '0$parsedMinutes' : parsedMinutes.toString();

  final parsedSeconds = duration.inSeconds % 60;

  final seconds =
  parsedSeconds < 10 ? '0$parsedSeconds' : parsedSeconds.toString();

  return '$minutes:$seconds';
}

IconData animatedVolumeIcon(double volume) {
  if (volume == 0)
    return Icons.volume_mute;
  else if (volume < 0.5)
    return Icons.volume_down;
  else
    return Icons.volume_up;
}



class _ControlsOverlay extends StatefulWidget {
  const _ControlsOverlay({Key key, this.controller}) : super(key: key);
  final VideoPlayerController controller;

  @override
  __ControlsOverlayState createState() => __ControlsOverlayState();
}

class __ControlsOverlayState extends State<_ControlsOverlay> {


  static const _examplePlaybackRates = [
    0.25,
    0.5,
    1.0,
    1.5,
    2.0,
    3.0,
    5.0,
    10.0,
  ];


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: Duration(milliseconds: 50),
          reverseDuration: Duration(milliseconds: 200),
          child: widget.controller.value.isPlaying
              ? SizedBox.shrink()
              : Container(
            color: Colors.black26,
            child: Center(
              child: Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 100.0,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              debugMessage("PLAYER: Before Tap  ${widget.controller.value.isPlaying}");
              widget.controller.value.isPlaying ? widget.controller.pause() : widget.controller
                  .play();
              debugMessage("PLAYER: After Tap ${widget.controller.value.isPlaying}");
            });
          },
        ),
        Align(
          alignment: Alignment.topRight,
          child: PopupMenuButton<double>(
            initialValue: widget.controller.value.playbackSpeed,
            tooltip: 'Playback speed',
            onSelected: (speed) {
              widget.controller.setPlaybackSpeed(speed);
            },
            itemBuilder: (context) {
              return [
                for (final speed in _examplePlaybackRates)
                  PopupMenuItem(
                    value: speed,
                    child: Text('${speed}x'),
                  )
              ];
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                // Using less vertical padding as the text is also longer
                // horizontally, so it feels like it would need more spacing
                // horizontally (matching the aspect ratio of the video).
                vertical: 12,
                horizontal: 16,
              ),
              child: Text('${widget.controller.value.playbackSpeed}x'),
            ),
          ),
        ),
      ],
    );
  }
}
