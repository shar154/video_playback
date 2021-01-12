
const bool showDebugMessages = false;
const bool openRecordedVideoForView = false;

void debugMessage(String message) {
  if(showDebugMessages)
    print('VIDEO_PLAYBACK: $message');
}

bool isSuitableValue(String val) => val!=null && val != '';
