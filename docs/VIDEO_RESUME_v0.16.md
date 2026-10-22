# PalEdu — private lesson-video resume

Saved playback position for approved teacher/trainer videos is now device-local. It uses a SHA-256 hash of the stable resource ID as its preference key. Temporary signed URLs, video bytes, and learner answers are **not** stored in the new playback preference.

The in-app player restores a prior position for videos with a known resource ID, when that position falls safely before the end of a video. It throttles position persistence to approximately 10-second progress intervals, and saves on navigation away. Existing video controls and in-app viewing remain unchanged. The existing Delete My Data action removes playback preferences.

This requires a real authenticated cloud backend to browse uploaded media. It does not bundle copyrighted videos or enable offline video playback. Further work: optional licensed downloads, network quality handling, content moderation, and server load tests.
